import CoreBluetooth
import Foundation

/// Internal CoreBluetooth wrapper that scans for, connects to, and exchanges
/// framed messages with a Tesla vehicle's GATT service. Owns the CBCentralManager
/// lifecycle and the `disconnected → scanning → connecting → connected` state
/// machine. BLE-layer failures surface as `BLEError`; the Dispatcher maps those
/// onto the public `TeslaBLEError` cases (e.g. `.notConnected`, `.timeout`,
/// `.disconnected`). Not public.
@preconcurrency
final class BLETransport: NSObject, Sendable {
    enum ConnectionState {
        case disconnected
        case scanning
        case connecting
        case connected
    }

    nonisolated(unsafe) static let vehicleServiceUUID = CBUUID(string: "00000211-b2d1-43f0-9b88-960cebf8b91e")
    nonisolated(unsafe) static let toVehicleUUID = CBUUID(string: "00000212-b2d1-43f0-9b88-960cebf8b91e")
    nonisolated(unsafe) static let fromVehicleUUID = CBUUID(string: "00000213-b2d1-43f0-9b88-960cebf8b91e")
    private static let maxMessageSize = 1024
    private static let rxTimeout: TimeInterval = 1.0
    private static let restorationIdentifier = "TeslaBLE.BLETransport.central"
    private static let knownPeripheralDefaultsPrefix = "TeslaBLE.knownPeripheral."

    // All mutable BLE state is confined to this serial queue. CoreBluetooth
    // delegate callbacks are also delivered on this queue via CBCentralManager.
    private let queue = DispatchQueue(label: "TeslaBLE.BLETransport", qos: .userInitiated)
    private let logger: (any TeslaBLELogger)?
    private nonisolated(unsafe) var centralManager: CBCentralManager!
    private nonisolated(unsafe) var peripheral: CBPeripheral?
    private nonisolated(unsafe) var txCharacteristic: CBCharacteristic?
    private nonisolated(unsafe) var rxCharacteristic: CBCharacteristic?
    private nonisolated(unsafe) var mtu: Int = 20
    private nonisolated(unsafe) var writeType: CBCharacteristicWriteType = .withResponse
    private nonisolated(unsafe) var targetLocalName: String?
    private nonisolated(unsafe) var targetPeripheralID: UUID?
    private nonisolated(unsafe) var restoredPeripherals: [CBPeripheral] = []
    private nonisolated(unsafe) var fallbackScanWorkItem: DispatchWorkItem?

    private nonisolated(unsafe) var inputBuffer = Data()
    private nonisolated(unsafe) var lastRxTime: Date?

    private nonisolated(unsafe) var connectionContinuation: CheckedContinuation<Void, Error>?
    private nonisolated(unsafe) var receiveContinuations: [CheckedContinuation<Data, Error>] = []

    private(set) nonisolated(unsafe) var state: ConnectionState = .disconnected
    nonisolated(unsafe) var onStateChange: (@Sendable (ConnectionState) -> Void)?

    init(logger: (any TeslaBLELogger)? = nil) {
        self.logger = logger
        super.init()
        centralManager = CBCentralManager(
            delegate: self,
            queue: queue,
            options: [CBCentralManagerOptionRestoreIdentifierKey: Self.restorationIdentifier],
        )
    }

    /// Scans for and connects to the vehicle with the given VIN.
    /// Times out after `timeout` seconds if vehicle is not found.
    func connect(vin: String, timeout: TimeInterval = 30) async throws {
        targetLocalName = VINHelper.bleLocalName(for: vin)
        targetPeripheralID = targetLocalName.flatMap { Self.loadKnownPeripheralID(for: $0) }
        logger?.log(.debug, category: "transport", "Target local name: \(targetLocalName ?? "nil") for VIN: \(vin), known peripheral: \(targetPeripheralID?.uuidString ?? "nil")")
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    self.queue.async { [self] in
                        connectionContinuation = continuation
                        if centralManager.state == .poweredOn {
                            startBestEffortConnect()
                        } else {
                            updateState(.scanning)
                            logger?.log(.debug, category: "transport", "Waiting for Bluetooth to power on (current state: \(centralManager.state.rawValue))")
                        }
                    }
                }
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw BLEError.timeout
            }
            // First to finish wins; cancel the other
            do {
                try await group.next()
                group.cancelAll()
            } catch {
                group.cancelAll()
                // Clean up scanning state
                self.queue.async { [self] in
                    fallbackScanWorkItem?.cancel()
                    fallbackScanWorkItem = nil
                    centralManager.stopScan()
                    if let peripheral, state == .connecting {
                        centralManager.cancelPeripheralConnection(peripheral)
                    }
                    if let cont = connectionContinuation {
                        connectionContinuation = nil
                        // Only resume if it was the timeout that fired
                        if error is BLEError {
                            cont.resume(throwing: error)
                        }
                    }
                    updateState(.disconnected)
                }
                throw error
            }
        }
    }

    private func startBestEffortConnect() {
        assertOnTransportQueue()
        fallbackScanWorkItem?.cancel()
        fallbackScanWorkItem = nil

        if let restored = restoredPeripherals.first(where: matchesTargetPeripheral) {
            logger?.log(.debug, category: "transport", "Reusing restored peripheral \(restored.identifier.uuidString)")
            connect(restored, source: "restored", allowFallbackScan: true)
            return
        }

        if let targetPeripheralID {
            let known = centralManager.retrievePeripherals(withIdentifiers: [targetPeripheralID])
            if let peripheral = known.first {
                logger?.log(.debug, category: "transport", "Retrieved known peripheral \(peripheral.identifier.uuidString), connecting before broad scan")
                connect(peripheral, source: "known-peripheral", allowFallbackScan: true)
                return
            }
        }

        let connected = centralManager.retrieveConnectedPeripherals(withServices: [Self.vehicleServiceUUID])
        if let peripheral = connected.first(where: matchesTargetPeripheral) {
            logger?.log(.debug, category: "transport", "Reusing already connected peripheral \(peripheral.identifier.uuidString)")
            connect(peripheral, source: "system-connected", allowFallbackScan: false)
            return
        }

        startScanning()
    }

    private func startScanning() {
        updateState(.scanning)
        logger?.log(.debug, category: "transport", "Starting scan for vehicle (no service filter, matching by local name)...")
        scanForTarget()
    }

    private func scanForTarget() {
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false],
        )
    }

    private func connect(_ peripheral: CBPeripheral, source: String, allowFallbackScan: Bool) {
        centralManager.stopScan()
        self.peripheral = peripheral
        peripheral.delegate = self
        remember(peripheral)
        updateState(.connecting)
        logger?.log(.debug, category: "transport", "Connecting to peripheral \(peripheral.identifier.uuidString) via \(source)")
        centralManager.connect(peripheral, options: nil)

        guard allowFallbackScan else { return }
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.queue.async { [self] in
                guard connectionContinuation != nil, state == .connecting else { return }
                logger?.log(.debug, category: "transport", "Known peripheral is still connecting; starting fallback scan without service filter")
                scanForTarget()
            }
        }
        fallbackScanWorkItem = workItem
        queue.asyncAfter(deadline: .now() + 3, execute: workItem)
    }

    private func matchesTargetPeripheral(_ peripheral: CBPeripheral) -> Bool {
        if let targetPeripheralID, peripheral.identifier == targetPeripheralID {
            return true
        }
        if let targetLocalName, peripheral.name == targetLocalName {
            return true
        }
        return false
    }

    private func remember(_ peripheral: CBPeripheral) {
        guard let targetLocalName else { return }
        targetPeripheralID = peripheral.identifier
        UserDefaults.standard.set(
            peripheral.identifier.uuidString,
            forKey: Self.knownPeripheralDefaultsKey(for: targetLocalName),
        )
    }

    private func clearPeripheralState() {
        peripheral = nil
        txCharacteristic = nil
        rxCharacteristic = nil
        inputBuffer = Data()
    }

    private static func knownPeripheralDefaultsKey(for localName: String) -> String {
        knownPeripheralDefaultsPrefix + localName
    }

    private static func loadKnownPeripheralID(for localName: String) -> UUID? {
        guard let value = UserDefaults.standard.string(forKey: knownPeripheralDefaultsKey(for: localName)) else {
            return nil
        }
        return UUID(uuidString: value)
    }

    /// Sends a protobuf-serialized RoutableMessage.
    func send(_ data: Data) throws {
        guard let peripheral, let txCharacteristic else {
            throw BLEError.notConnected
        }
        let framed = MessageFramer.encode(data)
        guard framed.count <= Self.maxMessageSize + 2 else {
            throw BLEError.messageTooLarge
        }
        let chunks = MessageFramer.fragment(framed, mtu: mtu)
        for chunk in chunks {
            peripheral.writeValue(chunk, for: txCharacteristic, type: writeType)
        }
    }

    /// Waits for the next complete message from the vehicle.
    func receive() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [self] in
                // Check if we already have a complete message buffered
                if let message = tryFlush() {
                    continuation.resume(returning: message)
                } else {
                    receiveContinuations.append(continuation)
                }
            }
        }
    }

    func disconnect() {
        queue.async { [self] in
            if let peripheral {
                centralManager.cancelPeripheralConnection(peripheral)
            }
            cleanup()
        }
    }

    private func cleanup() {
        fallbackScanWorkItem?.cancel()
        fallbackScanWorkItem = nil
        centralManager.stopScan()
        clearPeripheralState()
        updateState(.disconnected)
    }

    private func updateState(_ newState: ConnectionState) {
        state = newState
        onStateChange?(newState)
    }

    private func assertOnTransportQueue() {
        dispatchPrecondition(condition: .onQueue(queue))
    }

    private func tryFlush() -> Data? {
        guard inputBuffer.count >= 2 else { return nil }
        if let (message, consumed) = try? MessageFramer.decode(inputBuffer), let message {
            inputBuffer.removeFirst(consumed)
            return message
        }
        return nil
    }
}

// MARK: - CBCentralManagerDelegate

extension BLETransport: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        assertOnTransportQueue()
        logger?.log(.debug, category: "transport", "Central manager state changed: \(central.state.rawValue)")
        if central.state == .poweredOn {
            // If we're waiting to connect, start scanning now
            if connectionContinuation != nil, state != .connecting, state != .connected {
                startBestEffortConnect()
            }
        } else {
            connectionContinuation?.resume(throwing: BLEError.bluetoothUnavailable)
            connectionContinuation = nil
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber,
    ) {
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        assertOnTransportQueue()
        logger?.log(.debug, category: "transport", "Discovered: name=\(localName ?? "nil") peripheral=\(peripheral.name ?? "unnamed") rssi=\(RSSI) target=\(targetLocalName ?? "nil")")
        guard localName == targetLocalName else { return }
        logger?.log(.debug, category: "transport", "Found target vehicle! Connecting...")
        connect(peripheral, source: "scan", allowFallbackScan: false)
    }

    nonisolated func centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheral) {
        assertOnTransportQueue()
        fallbackScanWorkItem?.cancel()
        fallbackScanWorkItem = nil
        centralManager.stopScan()
        remember(peripheral)
        logger?.log(.debug, category: "transport", "Connected to peripheral, discovering services...")
        peripheral.discoverServices([Self.vehicleServiceUUID])
    }

    nonisolated func centralManager(
        _: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?,
    ) {
        assertOnTransportQueue()
        logger?.log(.warning, category: "transport", "Failed to connect to peripheral \(peripheral.identifier.uuidString): \(error?.localizedDescription ?? "unknown"); falling back to scan until timeout")
        guard connectionContinuation != nil else {
            cleanup()
            return
        }
        clearPeripheralState()
        startScanning()
    }

    nonisolated func centralManager(
        _: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error _: Error?,
    ) {
        assertOnTransportQueue()
        if connectionContinuation != nil {
            logger?.log(.warning, category: "transport", "Peripheral \(peripheral.identifier.uuidString) disconnected during connection; falling back to scan until timeout")
            clearPeripheralState()
            startScanning()
            return
        }
        cleanup()
        // Fail any pending receives
        for cont in receiveContinuations {
            cont.resume(throwing: BLEError.disconnected)
        }
        receiveContinuations.removeAll()
    }

    nonisolated func centralManager(
        _: CBCentralManager,
        willRestoreState dict: [String: Any],
    ) {
        assertOnTransportQueue()
        guard let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral],
              !peripherals.isEmpty else { return }
        restoredPeripherals = peripherals
        for peripheral in peripherals {
            peripheral.delegate = self
        }
        logger?.log(.debug, category: "transport", "Restored \(peripherals.count) peripheral(s) from CoreBluetooth state restoration")
        if connectionContinuation != nil, centralManager.state == .poweredOn {
            startBestEffortConnect()
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLETransport: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices _: Error?) {
        assertOnTransportQueue()
        guard let service = peripheral.services?.first(where: { $0.uuid == Self.vehicleServiceUUID }) else {
            connectionContinuation?.resume(throwing: BLEError.serviceNotFound)
            connectionContinuation = nil
            return
        }
        peripheral.discoverCharacteristics(
            [Self.toVehicleUUID, Self.fromVehicleUUID],
            for: service,
        )
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error _: Error?,
    ) {
        assertOnTransportQueue()
        guard let characteristics = service.characteristics else {
            connectionContinuation?.resume(throwing: BLEError.characteristicsNotFound)
            connectionContinuation = nil
            return
        }
        for char in characteristics {
            if char.uuid == Self.toVehicleUUID {
                txCharacteristic = char
            } else if char.uuid == Self.fromVehicleUUID {
                rxCharacteristic = char
                peripheral.setNotifyValue(true, for: char)
            }
        }
        // Use writeWithResponse if the characteristic doesn't support writeWithoutResponse.
        // Tesla vehicles typically advertise property 0x8 (write with response only).
        if let tx = txCharacteristic, tx.properties.contains(.writeWithoutResponse) {
            writeType = .withoutResponse
            mtu = peripheral.maximumWriteValueLength(for: .withoutResponse)
        } else {
            writeType = .withResponse
            mtu = peripheral.maximumWriteValueLength(for: .withResponse)
        }
        logger?.log(.debug, category: "transport", "Characteristics discovered. TX=\(txCharacteristic != nil) RX=\(rxCharacteristic != nil) MTU=\(mtu) writeType=\(writeType == .withResponse ? "withResponse" : "withoutResponse") txProperties=\(txCharacteristic?.properties.rawValue ?? 0)")
        updateState(.connected)
        connectionContinuation?.resume()
        connectionContinuation = nil
    }

    nonisolated func peripheral(
        _: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error _: Error?,
    ) {
        assertOnTransportQueue()
        guard characteristic.uuid == Self.fromVehicleUUID,
              let value = characteristic.value else { return }

        let now = Date()
        if let lastRx = lastRxTime, now.timeIntervalSince(lastRx) > Self.rxTimeout {
            if !inputBuffer.isEmpty {
                logger?.log(
                    .warning,
                    category: "transport",
                    "RX buffer reset: \(String(format: "%.2f", now.timeIntervalSince(lastRx)))s gap > \(Self.rxTimeout)s timeout, discarding \(inputBuffer.count) buffered bytes (likely a stalled multi-fragment response)",
                )
            }
            inputBuffer = Data()
        }
        lastRxTime = now
        inputBuffer.append(value)

        // How many bytes the current frame needs (2-byte length prefix), for visibility.
        var expected = -1
        if inputBuffer.count >= 2 {
            expected = 2 + (Int(inputBuffer[inputBuffer.startIndex]) << 8 | Int(inputBuffer[inputBuffer.startIndex + 1]))
        }
        logger?.log(
            .debug,
            category: "transport",
            "RX fragment \(value.count)B; buffered \(inputBuffer.count)\(expected > 0 ? "/\(expected)" : "")B",
        )

        // Deliver complete messages to waiting receivers.
        // Only extract when someone is waiting — otherwise leave in inputBuffer
        // so the next receive() call picks it up via tryFlush().
        while !receiveContinuations.isEmpty, let message = tryFlush() {
            logger?.log(.debug, category: "transport", "RX message reassembled: \(message.count)B; \(inputBuffer.count)B left in buffer")
            let continuation = receiveContinuations.removeFirst()
            continuation.resume(returning: message)
        }
    }
}

enum BLEError: Error {
    case bluetoothUnavailable
    case notConnected
    case connectionFailed
    case disconnected
    case serviceNotFound
    case characteristicsNotFound
    case messageTooLarge
    case timeout
}
