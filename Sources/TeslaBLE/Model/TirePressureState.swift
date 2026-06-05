import Foundation

/// Per-wheel tire pressure readings and recommended cold pressures.
public struct TirePressureState: Sendable, Equatable {
    /// Pressure and warning flag for a single wheel.
    public struct Tire: Sendable, Equatable {
        /// Measured tire pressure in bar. Nil if the vehicle did not report this field.
        public var pressureBar: Double?
        /// `true` if either a soft or hard TPMS warning is active for this wheel. Nil if the vehicle did not report this field.
        public var hasWarning: Bool?
        /// When this wheel's pressure was last measured (seconds since the Unix
        /// epoch). Nil if the vehicle did not report this field.
        public var lastSeenSecondsSinceEpoch: Int64?

        public init(
            pressureBar: Double? = nil,
            hasWarning: Bool? = nil,
            lastSeenSecondsSinceEpoch: Int64? = nil,
        ) {
            self.pressureBar = pressureBar
            self.hasWarning = hasWarning
            self.lastSeenSecondsSinceEpoch = lastSeenSecondsSinceEpoch
        }
    }

    /// Front-left wheel reading. Nil if the vehicle did not report this wheel.
    public var frontLeft: Tire?
    /// Front-right wheel reading. Nil if the vehicle did not report this wheel.
    public var frontRight: Tire?
    /// Rear-left wheel reading. Nil if the vehicle did not report this wheel.
    public var rearLeft: Tire?
    /// Rear-right wheel reading. Nil if the vehicle did not report this wheel.
    public var rearRight: Tire?
    /// Recommended cold front-axle tire pressure in bar. Nil if the vehicle did not report this field.
    public var recommendedColdFrontBar: Double?
    /// Recommended cold rear-axle tire pressure in bar. Nil if the vehicle did not report this field.
    public var recommendedColdRearBar: Double?

    public init(
        frontLeft: Tire? = nil,
        frontRight: Tire? = nil,
        rearLeft: Tire? = nil,
        rearRight: Tire? = nil,
        recommendedColdFrontBar: Double? = nil,
        recommendedColdRearBar: Double? = nil,
    ) {
        self.frontLeft = frontLeft
        self.frontRight = frontRight
        self.rearLeft = rearLeft
        self.rearRight = rearRight
        self.recommendedColdFrontBar = recommendedColdFrontBar
        self.recommendedColdRearBar = recommendedColdRearBar
    }
}
