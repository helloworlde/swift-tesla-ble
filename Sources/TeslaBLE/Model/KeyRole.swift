import Foundation

/// Role assigned to a key registered in the vehicle's whitelist.
///
/// Mirrors `Keys_Role` (8 roles). Most personal BLE pairings use
/// ``owner`` or ``driver``; the remaining roles exist on the wire for
/// fleet/managed-charging scenarios. Unknown wire values are preserved
/// in ``unrecognized(_:)`` rather than collapsing to a sentinel.
public enum KeyRole: Sendable, Equatable {
    /// No role assigned.
    case none
    /// Service-mode key — granted to Tesla service technicians.
    case service
    /// Full control, including the ability to add and remove other keys.
    case owner
    /// Can drive the vehicle but cannot manage other keys.
    case driver
    /// Fleet manager.
    case fleetManager
    /// Vehicle monitor — read-only telemetry access.
    case vehicleMonitor
    /// Charging-only manager.
    case chargingManager
    /// Guest key.
    case guest
    /// Wire value the SDK does not yet recognise.
    case unrecognized(Int)
}

/// Form-factor metadata attached to a key, shown by the vehicle in its
/// key-management UI.
///
/// Mirrors `VCSEC_KeyFormFactor`. Unknown wire values are preserved
/// in ``unrecognized(_:)``.
public enum KeyFormFactor: Sendable, Equatable {
    /// Form factor not reported.
    case unknown
    /// Tesla NFC key card.
    case nfcCard
    /// iOS device running the Tesla or a third-party app.
    case iosDevice
    /// Android device running the Tesla or a third-party app.
    case androidDevice
    /// Cloud-managed key.
    case cloudKey
    /// Wire value the SDK does not yet recognise.
    case unrecognized(Int)
}
