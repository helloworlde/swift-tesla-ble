@testable import TeslaBLE
import XCTest

final class VCSECStatusMapperTests: XCTestCase {
    func testMapsAllFields() {
        var closures = VCSEC_ClosureStatuses()
        closures.frontDriverDoor = .closurestateOpen
        closures.frontPassengerDoor = .closurestateAjar
        closures.rearDriverDoor = .closurestateClosed
        closures.rearPassengerDoor = .closurestateOpening
        closures.rearTrunk = .closurestateClosing
        closures.frontTrunk = .closurestateFailedUnlatch
        closures.chargePort = .closurestateUnknown
        closures.tonneau = .closurestateOpen

        var detail = VCSEC_DetailedClosureStatus()
        detail.tonneauPercentOpen = 42

        var status = VCSEC_VehicleStatus()
        status.closureStatuses = closures
        status.vehicleLockState = .vehiclelockstateInternalLocked
        status.vehicleSleepStatus = .vehicleSleepStatusAwake
        status.userPresence = .vehicleUserPresencePresent
        status.detailedClosureStatus = detail

        let result = VCSECStatusMapper.map(status)

        XCTAssertEqual(result.closures.frontDriverDoor, .open)
        XCTAssertEqual(result.closures.frontPassengerDoor, .ajar)
        XCTAssertEqual(result.closures.rearDriverDoor, .closed)
        XCTAssertEqual(result.closures.rearPassengerDoor, .opening)
        XCTAssertEqual(result.closures.rearTrunk, .closing)
        XCTAssertEqual(result.closures.frontTrunk, .failedUnlatch)
        XCTAssertEqual(result.closures.chargePort, .unknown)
        XCTAssertEqual(result.closures.tonneau, .open)
        XCTAssertEqual(result.lockState, .internalLocked)
        XCTAssertEqual(result.sleepStatus, .awake)
        XCTAssertEqual(result.userPresence, .present)
        XCTAssertEqual(result.tonneauPercentOpen, 42)
    }

    func testTonneauPercentOpenIsNilWhenDetailedStatusAbsent() {
        var status = VCSEC_VehicleStatus()
        status.vehicleLockState = .vehiclelockstateLocked
        status.vehicleSleepStatus = .vehicleSleepStatusAsleep
        status.userPresence = .vehicleUserPresenceNotPresent

        let result = VCSECStatusMapper.map(status)
        XCTAssertNil(result.tonneauPercentOpen)
        XCTAssertEqual(result.lockState, .locked)
        XCTAssertEqual(result.sleepStatus, .asleep)
        XCTAssertEqual(result.userPresence, .notPresent)
    }

    func testClosureStatusesDefaultsToClosedWhenSubmessageAbsent() {
        let status = VCSEC_VehicleStatus()
        let result = VCSECStatusMapper.map(status)
        XCTAssertEqual(result.closures.frontDriverDoor, .closed)
        XCTAssertEqual(result.closures.tonneau, .closed)
    }

    func testUnrecognizedClosureValuePreserved() {
        var closures = VCSEC_ClosureStatuses()
        closures.frontDriverDoor = .UNRECOGNIZED(99)
        var status = VCSEC_VehicleStatus()
        status.closureStatuses = closures
        let result = VCSECStatusMapper.map(status)
        XCTAssertEqual(result.closures.frontDriverDoor, .unrecognized(99))
    }

    // MARK: - Whitelist mapping

    func testWhitelistInfoMapping() {
        var info = VCSEC_WhitelistInfo()
        info.numberOfEntries = 3
        info.slotMask = 0b1011

        var entry1 = VCSEC_KeyIdentifier()
        entry1.publicKeySha1 = Data([0x01, 0x02, 0x03, 0x04])
        var entry2 = VCSEC_KeyIdentifier()
        entry2.publicKeySha1 = Data([0xAA, 0xBB])
        info.whitelistEntries = [entry1, entry2]

        let result = VCSECStatusMapper.map(info)
        XCTAssertEqual(result.numberOfEntries, 3)
        XCTAssertEqual(result.slotMask, 0b1011)
        XCTAssertEqual(result.entries.count, 2)
        XCTAssertEqual(result.entries[0].publicKeySha1, Data([0x01, 0x02, 0x03, 0x04]))
        XCTAssertEqual(result.entries[1].publicKeySha1, Data([0xAA, 0xBB]))
    }

    func testWhitelistEntryMapping() {
        var keyID = VCSEC_KeyIdentifier()
        keyID.publicKeySha1 = Data([0xDE, 0xAD, 0xBE, 0xEF])
        var pubKey = VCSEC_PublicKey()
        pubKey.publicKeyRaw = Data(repeating: 0x04, count: 65)
        var meta = VCSEC_KeyMetadata()
        meta.keyFormFactor = .iosDevice

        var entry = VCSEC_WhitelistEntryInfo()
        entry.keyID = keyID
        entry.publicKey = pubKey
        entry.metadataForKey = meta
        entry.slot = 7
        entry.keyRole = .driver

        let result = VCSECStatusMapper.map(entry)
        XCTAssertEqual(result.keyIdentifier?.publicKeySha1, Data([0xDE, 0xAD, 0xBE, 0xEF]))
        XCTAssertEqual(result.publicKey?.count, 65)
        XCTAssertEqual(result.formFactor, .iosDevice)
        XCTAssertEqual(result.slot, 7)
        XCTAssertEqual(result.role, .driver)
    }

    func testWhitelistEntryUnsetSubmessagesAreNil() {
        var entry = VCSEC_WhitelistEntryInfo()
        entry.slot = 0
        entry.keyRole = .owner

        let result = VCSECStatusMapper.map(entry)
        XCTAssertNil(result.keyIdentifier)
        XCTAssertNil(result.publicKey)
        XCTAssertNil(result.formFactor)
        XCTAssertEqual(result.role, .owner)
    }

    func testKeyRoleAllVariantsRoundTrip() {
        let cases: [(Keys_Role, KeyRole)] = [
            (.none, .none),
            (.service, .service),
            (.owner, .owner),
            (.driver, .driver),
            (.fm, .fleetManager),
            (.vehicleMonitor, .vehicleMonitor),
            (.chargingManager, .chargingManager),
            (.guest, .guest),
        ]
        for (raw, expected) in cases {
            XCTAssertEqual(VCSECStatusMapper.mapKeyRole(raw), expected)
        }
        XCTAssertEqual(VCSECStatusMapper.mapKeyRole(.UNRECOGNIZED(42)), .unrecognized(42))
    }

    func testKeyFormFactorAllVariantsRoundTrip() {
        let cases: [(VCSEC_KeyFormFactor, KeyFormFactor)] = [
            (.unknown, .unknown),
            (.nfcCard, .nfcCard),
            (.iosDevice, .iosDevice),
            (.androidDevice, .androidDevice),
            (.cloudKey, .cloudKey),
        ]
        for (raw, expected) in cases {
            XCTAssertEqual(VCSECStatusMapper.mapFormFactor(raw), expected)
        }
        XCTAssertEqual(VCSECStatusMapper.mapFormFactor(.UNRECOGNIZED(99)), .unrecognized(99))
    }
}
