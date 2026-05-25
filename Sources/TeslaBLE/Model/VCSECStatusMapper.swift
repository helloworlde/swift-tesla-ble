import Foundation

/// Internal bridge from `VCSEC_VehicleStatus` to the public Swift-native
/// `BodyControllerState`.
///
/// Sibling of ``VehicleSnapshotMapper`` — kept in `Sources/TeslaBLE/Model/`
/// alongside the Swift model types so that `VCSEC_*` protobuf imports
/// stay confined to mapper files.
enum VCSECStatusMapper {
    static func map(_ pb: VCSEC_VehicleStatus) -> BodyControllerState {
        BodyControllerState(
            closures: pb.hasClosureStatuses
                ? mapClosures(pb.closureStatuses) : BodyControllerState.ClosureStatuses(),
            lockState: mapLockState(pb.vehicleLockState),
            sleepStatus: mapSleepStatus(pb.vehicleSleepStatus),
            userPresence: mapUserPresence(pb.userPresence),
            tonneauPercentOpen: pb.hasDetailedClosureStatus
                ? pb.detailedClosureStatus.tonneauPercentOpen : nil,
        )
    }

    // MARK: - Sub-mappers

    private static func mapClosures(
        _ pb: VCSEC_ClosureStatuses,
    ) -> BodyControllerState.ClosureStatuses {
        BodyControllerState.ClosureStatuses(
            frontDriverDoor: mapClosure(pb.frontDriverDoor),
            frontPassengerDoor: mapClosure(pb.frontPassengerDoor),
            rearDriverDoor: mapClosure(pb.rearDriverDoor),
            rearPassengerDoor: mapClosure(pb.rearPassengerDoor),
            rearTrunk: mapClosure(pb.rearTrunk),
            frontTrunk: mapClosure(pb.frontTrunk),
            chargePort: mapClosure(pb.chargePort),
            tonneau: mapClosure(pb.tonneau),
        )
    }

    private static func mapClosure(
        _ pb: VCSEC_ClosureState_E,
    ) -> BodyControllerState.ClosureState {
        switch pb {
        case .closurestateClosed: .closed
        case .closurestateOpen: .open
        case .closurestateAjar: .ajar
        case .closurestateUnknown: .unknown
        case .closurestateFailedUnlatch: .failedUnlatch
        case .closurestateOpening: .opening
        case .closurestateClosing: .closing
        case .UNRECOGNIZED(let i): .unrecognized(i)
        }
    }

    private static func mapLockState(
        _ pb: VCSEC_VehicleLockState_E,
    ) -> BodyControllerState.LockState {
        switch pb {
        case .vehiclelockstateUnlocked: .unlocked
        case .vehiclelockstateLocked: .locked
        case .vehiclelockstateInternalLocked: .internalLocked
        case .vehiclelockstateSelectiveUnlocked: .selectiveUnlocked
        case .UNRECOGNIZED(let i): .unrecognized(i)
        }
    }

    private static func mapSleepStatus(
        _ pb: VCSEC_VehicleSleepStatus_E,
    ) -> BodyControllerState.SleepStatus {
        switch pb {
        case .vehicleSleepStatusUnknown: .unknown
        case .vehicleSleepStatusAwake: .awake
        case .vehicleSleepStatusAsleep: .asleep
        case .UNRECOGNIZED(let i): .unrecognized(i)
        }
    }

    private static func mapUserPresence(
        _ pb: VCSEC_UserPresence_E,
    ) -> BodyControllerState.UserPresence {
        switch pb {
        case .vehicleUserPresenceUnknown: .unknown
        case .vehicleUserPresenceNotPresent: .notPresent
        case .vehicleUserPresencePresent: .present
        case .UNRECOGNIZED(let i): .unrecognized(i)
        }
    }
}
