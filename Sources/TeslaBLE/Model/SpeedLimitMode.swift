import Foundation

/// Speed-limit mode (Valet / parental) sub-state of `ClosuresState`.
///
/// Mirrors `CarServer_SpeedLimitMode` from the upstream Go SDK. Every field
/// is optional — an absent oneof stays `nil`.
public struct SpeedLimitMode: Sendable, Equatable {
    /// True if speed-limit mode is currently engaged.
    public var active: Bool?
    /// True if a PIN has been configured for this mode.
    public var pinCodeSet: Bool?
    /// Maximum settable speed limit, in mph.
    public var maxLimitMph: Double?
    /// Minimum settable speed limit, in mph.
    public var minLimitMph: Double?
    /// Currently configured speed limit, in mph.
    public var currentLimitMph: Double?

    public init(
        active: Bool? = nil,
        pinCodeSet: Bool? = nil,
        maxLimitMph: Double? = nil,
        minLimitMph: Double? = nil,
        currentLimitMph: Double? = nil,
    ) {
        self.active = active
        self.pinCodeSet = pinCodeSet
        self.maxLimitMph = maxLimitMph
        self.minLimitMph = minLimitMph
        self.currentLimitMph = currentLimitMph
    }
}
