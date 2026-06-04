import Foundation

/// VCSEC body-controller state — door / closure positions, lock state,
/// sleep status, user presence.
///
/// This is the Swift-native projection of `VCSEC_VehicleStatus` returned
/// by `VehicleQuery.bodyControllerState`. Unknown wire enum values are
/// preserved in `.unknown(Int)` rather than collapsing to a sentinel,
/// so callers can distinguish "vehicle reported a value the SDK doesn't
/// know about yet" from "vehicle didn't report this".
public struct BodyControllerState: Sendable, Equatable {
    /// Door, trunk, frunk, charge port, and tonneau closure states.
    public var closures: ClosureStatuses
    /// Aggregated lock state of the cabin.
    public var lockState: LockState
    /// Whether Infotainment is awake or asleep. Note this status can lag
    /// the actual MCU state by up to ~30 s.
    public var sleepStatus: SleepStatus
    /// Whether a user is detected inside or near the vehicle.
    public var userPresence: UserPresence
    /// Tonneau open percentage, 0–100. Nil if the vehicle did not
    /// report `detailedClosureStatus`.
    public var tonneauPercentOpen: UInt32?

    public init(
        closures: ClosureStatuses = ClosureStatuses(),
        lockState: LockState = .unlocked,
        sleepStatus: SleepStatus = .unknown,
        userPresence: UserPresence = .unknown,
        tonneauPercentOpen: UInt32? = nil,
    ) {
        self.closures = closures
        self.lockState = lockState
        self.sleepStatus = sleepStatus
        self.userPresence = userPresence
        self.tonneauPercentOpen = tonneauPercentOpen
    }

    /// Position of every reportable closure. Mirrors `VCSEC_ClosureStatuses`.
    public struct ClosureStatuses: Sendable, Equatable {
        public var frontDriverDoor: ClosureState
        public var frontPassengerDoor: ClosureState
        public var rearDriverDoor: ClosureState
        public var rearPassengerDoor: ClosureState
        public var rearTrunk: ClosureState
        public var frontTrunk: ClosureState
        public var chargePort: ClosureState
        public var tonneau: ClosureState

        public init(
            frontDriverDoor: ClosureState = .closed,
            frontPassengerDoor: ClosureState = .closed,
            rearDriverDoor: ClosureState = .closed,
            rearPassengerDoor: ClosureState = .closed,
            rearTrunk: ClosureState = .closed,
            frontTrunk: ClosureState = .closed,
            chargePort: ClosureState = .closed,
            tonneau: ClosureState = .closed,
        ) {
            self.frontDriverDoor = frontDriverDoor
            self.frontPassengerDoor = frontPassengerDoor
            self.rearDriverDoor = rearDriverDoor
            self.rearPassengerDoor = rearPassengerDoor
            self.rearTrunk = rearTrunk
            self.frontTrunk = frontTrunk
            self.chargePort = chargePort
            self.tonneau = tonneau
        }
    }

    /// Per-closure position. Mirrors `VCSEC_ClosureState_E`.
    public enum ClosureState: Sendable, Equatable {
        case closed
        case open
        case ajar
        case unknown
        case failedUnlatch
        case opening
        case closing
        case unrecognized(Int)
    }

    /// Aggregate cabin lock state. Mirrors `VCSEC_VehicleLockState_E`.
    public enum LockState: Sendable, Equatable {
        case unlocked
        case locked
        case internalLocked
        case selectiveUnlocked
        case unrecognized(Int)
    }

    /// Whether Infotainment is awake. Mirrors `VCSEC_VehicleSleepStatus_E`.
    public enum SleepStatus: Sendable, Equatable {
        case unknown
        case awake
        case asleep
        case unrecognized(Int)
    }

    /// User presence as detected by VCSEC. Mirrors `VCSEC_UserPresence_E`.
    public enum UserPresence: Sendable, Equatable {
        case unknown
        case notPresent
        case present
        case unrecognized(Int)
    }
}
