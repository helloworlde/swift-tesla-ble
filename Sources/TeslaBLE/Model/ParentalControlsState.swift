import Foundation

/// Parental-controls (Speed Limit Mode) status reported by the vehicle.
public struct ParentalControlsState: Sendable, Equatable {
    /// Whether parental controls are currently engaged. Nil if the vehicle did not report this field.
    public var active: Bool?
    /// Whether a parental-controls PIN has been configured on the vehicle. Nil if the vehicle did not report this field.
    public var pinSet: Bool?
    /// Detailed parental-controls settings sub-state. Nil if the vehicle did
    /// not report any settings fields.
    public var settings: ParentalControlsSettings?

    public init(
        active: Bool? = nil,
        pinSet: Bool? = nil,
        settings: ParentalControlsSettings? = nil,
    ) {
        self.active = active
        self.pinSet = pinSet
        self.settings = settings
    }
}

/// Detailed parental-controls (Speed Limit + curfew) settings sub-state.
///
/// Mirrors `CarServer_ParentalControlsSettings`. Each field is optional —
/// an absent oneof stays `nil` rather than being defaulted.
public struct ParentalControlsSettings: Sendable, Equatable {
    /// Speed limit enforcement enabled.
    public var speedLimitEnabled: Bool?
    /// Maximum settable speed limit, in mph.
    public var maxLimitMph: Double?
    /// Minimum settable speed limit, in mph.
    public var minLimitMph: Double?
    /// Currently configured speed limit, in mph.
    public var currentLimitMph: Double?
    /// Chill-acceleration mode enabled (capped throttle response).
    public var chillAccelerationEnabled: Bool?
    /// Forces safety-critical settings on (stability/traction control, etc.).
    public var requireSafetySettingsEnabled: Bool?
    /// Curfew enforcement enabled.
    public var curfewEnabled: Bool?
    /// Curfew start time. Encoding mirrors the upstream proto value (typically
    /// seconds-of-day or minutes-of-day).
    public var curfewStartTime: Int?
    /// Curfew end time. Same encoding as `curfewStartTime`.
    public var curfewEndTime: Int?

    public init(
        speedLimitEnabled: Bool? = nil,
        maxLimitMph: Double? = nil,
        minLimitMph: Double? = nil,
        currentLimitMph: Double? = nil,
        chillAccelerationEnabled: Bool? = nil,
        requireSafetySettingsEnabled: Bool? = nil,
        curfewEnabled: Bool? = nil,
        curfewStartTime: Int? = nil,
        curfewEndTime: Int? = nil,
    ) {
        self.speedLimitEnabled = speedLimitEnabled
        self.maxLimitMph = maxLimitMph
        self.minLimitMph = minLimitMph
        self.currentLimitMph = currentLimitMph
        self.chillAccelerationEnabled = chillAccelerationEnabled
        self.requireSafetySettingsEnabled = requireSafetySettingsEnabled
        self.curfewEnabled = curfewEnabled
        self.curfewStartTime = curfewStartTime
        self.curfewEndTime = curfewEndTime
    }
}
