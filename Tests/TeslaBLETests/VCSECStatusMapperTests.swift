import XCTest
@testable import TeslaBLE

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
}
