import Foundation

/// Doors, windows, trunks, sunroof, tonneau, and security/occupancy status.
public struct ClosuresState: Sendable, Equatable {
    // MARK: Doors

    /// `true` if the front-left door is open. Nil if the vehicle did not report this field.
    public var frontDriverDoor: Bool?
    /// `true` if the front-right door is open. Nil if the vehicle did not report this field.
    public var frontPassengerDoor: Bool?
    /// `true` if the rear-left door is open. Nil if the vehicle did not report this field.
    public var rearDriverDoor: Bool?
    /// `true` if the rear-right door is open. Nil if the vehicle did not report this field.
    public var rearPassengerDoor: Bool?
    /// `true` if the front trunk (frunk) is open. Nil if the vehicle did not report this field.
    public var frontTrunk: Bool?
    /// `true` if the rear trunk is open. Nil if the vehicle did not report this field.
    public var rearTrunk: Bool?

    /// `true` if the vehicle is currently locked. Nil if the vehicle did not report this field.
    public var locked: Bool?

    // MARK: Windows

    /// `true` if the front-left window is not fully closed. Nil if the vehicle did not report this field.
    public var windowDriverFront: Bool?
    /// `true` if the front-right window is not fully closed. Nil if the vehicle did not report this field.
    public var windowPassengerFront: Bool?
    /// `true` if the rear-left window is not fully closed. Nil if the vehicle did not report this field.
    public var windowDriverRear: Bool?
    /// `true` if the rear-right window is not fully closed. Nil if the vehicle did not report this field.
    public var windowPassengerRear: Bool?

    // MARK: Sunroof

    /// Current sunroof position state. Nil if the vehicle did not report this field or has no sunroof.
    public var sunroofState: SunroofState?
    /// Sunroof aperture as a percentage (0 = closed, 100 = fully open). Nil if the vehicle did not report this field.
    public var sunroofPercentOpen: Int?

    // MARK: Tonneau (Cybertruck)

    /// Tonneau cover position. Nil if the vehicle has no tonneau.
    public var tonneauState: TonneauState?
    /// Tonneau aperture as a percentage (0 = closed, 100 = fully open).
    public var tonneauPercentOpen: Int?
    /// True while the tonneau is actively moving between positions.
    public var tonneauInMotion: Bool?

    // MARK: Display / security

    /// Center-display power/UI state.
    public var centerDisplayState: DisplayState?
    /// Whether Sentry Mode is currently armed/active. Nil if the vehicle did not report this field.
    public var sentryModeActive: Bool?
    /// Whether the vehicle hardware/firmware supports Sentry Mode.
    public var sentryModeAvailable: Bool?
    /// True if a remote start session is active.
    public var remoteStart: Bool?
    /// Whether Valet Mode is enabled. Nil if the vehicle did not report this field.
    public var valetMode: Bool?
    /// True if exiting Valet Mode requires the valet PIN.
    public var valetPinNeeded: Bool?
    /// Whether the vehicle detects an occupant present. Nil if the vehicle did not report this field.
    public var isUserPresent: Bool?

    // MARK: Speed limit (parental / valet)

    /// Speed-limit mode sub-state. Nil if the vehicle did not report any
    /// speed-limit fields.
    public var speedLimit: SpeedLimitMode?

    /// Sunroof position state.
    public enum SunroofState: Sendable, Equatable {
        /// Fully closed.
        case closed
        /// Fully open (slid back).
        case open
        /// In vent / tilt position.
        case vent
        /// Actively moving between positions.
        case moving
        /// Performing a calibration cycle.
        case calibrating
        /// State not reported or unrecognized by the vehicle.
        case unknown
    }

    /// Tonneau cover position state. Mirrors `VCSEC_ClosureState_E`.
    public enum TonneauState: Sendable, Equatable {
        case closed
        case open
        case ajar
        case unknown
        case failedUnlatch
        case opening
        case closing
    }

    /// Center-display power state.
    public enum DisplayState: Sendable, Equatable {
        case off
        case dim
        case accessory
        case on
        case driving
        case charging
        case lock
        case sentry
        case dog
        case entertainment
    }

    public init(
        frontDriverDoor: Bool? = nil,
        frontPassengerDoor: Bool? = nil,
        rearDriverDoor: Bool? = nil,
        rearPassengerDoor: Bool? = nil,
        frontTrunk: Bool? = nil,
        rearTrunk: Bool? = nil,
        locked: Bool? = nil,
        windowDriverFront: Bool? = nil,
        windowPassengerFront: Bool? = nil,
        windowDriverRear: Bool? = nil,
        windowPassengerRear: Bool? = nil,
        sunroofState: SunroofState? = nil,
        sunroofPercentOpen: Int? = nil,
        tonneauState: TonneauState? = nil,
        tonneauPercentOpen: Int? = nil,
        tonneauInMotion: Bool? = nil,
        centerDisplayState: DisplayState? = nil,
        sentryModeActive: Bool? = nil,
        sentryModeAvailable: Bool? = nil,
        remoteStart: Bool? = nil,
        valetMode: Bool? = nil,
        valetPinNeeded: Bool? = nil,
        isUserPresent: Bool? = nil,
        speedLimit: SpeedLimitMode? = nil,
    ) {
        self.frontDriverDoor = frontDriverDoor
        self.frontPassengerDoor = frontPassengerDoor
        self.rearDriverDoor = rearDriverDoor
        self.rearPassengerDoor = rearPassengerDoor
        self.frontTrunk = frontTrunk
        self.rearTrunk = rearTrunk
        self.locked = locked
        self.windowDriverFront = windowDriverFront
        self.windowPassengerFront = windowPassengerFront
        self.windowDriverRear = windowDriverRear
        self.windowPassengerRear = windowPassengerRear
        self.sunroofState = sunroofState
        self.sunroofPercentOpen = sunroofPercentOpen
        self.tonneauState = tonneauState
        self.tonneauPercentOpen = tonneauPercentOpen
        self.tonneauInMotion = tonneauInMotion
        self.centerDisplayState = centerDisplayState
        self.sentryModeActive = sentryModeActive
        self.sentryModeAvailable = sentryModeAvailable
        self.remoteStart = remoteStart
        self.valetMode = valetMode
        self.valetPinNeeded = valetPinNeeded
        self.isUserPresent = isUserPresent
        self.speedLimit = speedLimit
    }
}
