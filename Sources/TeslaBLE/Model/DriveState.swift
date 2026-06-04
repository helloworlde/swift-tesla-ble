import Foundation

/// Gear, speed, power, odometer, and active-route status reported by the vehicle.
public struct DriveState: Sendable, Equatable {
    /// Current transmission position (P/R/N/D). Nil if the vehicle did not report this field.
    public var shiftState: ShiftState?
    /// Current ground speed in miles per hour. Nil if the vehicle did not report this field.
    public var speedMph: Double?
    /// Instantaneous drivetrain power in kilowatts (negative while regenerating). Nil if the vehicle did not report this field.
    public var powerKW: Int?
    /// Odometer reading in hundredths of a mile (divide by 100 to get miles). Nil if the vehicle did not report this field.
    public var odometerHundredthsMile: Int?

    // MARK: Active route

    /// Active navigation destination name, if any. Nil if the vehicle did not report this field.
    public var activeRouteDestination: String?
    /// Estimated minutes remaining on the active route. Nil if the vehicle did not report this field.
    public var activeRouteMinutesToArrival: Double?
    /// Remaining distance on the active route in miles. Nil if the vehicle did not report this field.
    public var activeRouteMilesToArrival: Double?
    /// Extra minutes of delay attributable to traffic on the active route.
    public var activeRouteTrafficMinutesDelay: Double?
    /// Estimated energy (in kWh / configured units) remaining at arrival.
    public var activeRouteEnergyAtArrival: Double?
    /// Active-route destination coordinates.
    public var activeRouteCoordinates: Coordinate?
    /// Last time the route ETA/distance fields were refreshed (seconds since
    /// the Unix epoch).
    public var lastRouteUpdateSecondsSinceEpoch: UInt32?
    /// Last time the traffic-delay field was refreshed (seconds since the
    /// Unix epoch).
    public var lastTrafficUpdateSecondsSinceEpoch: Int64?

    // MARK: Snapshot timestamp

    /// When the vehicle stamped this drive snapshot (seconds since the Unix
    /// epoch).
    public var timestampSecondsSinceEpoch: Int64?

    /// Transmission gear position.
    public enum ShiftState: Sendable, Equatable {
        /// Park.
        case park
        /// Reverse.
        case reverse
        /// Neutral.
        case neutral
        /// Drive.
        case drive
    }

    public init(
        shiftState: ShiftState? = nil,
        speedMph: Double? = nil,
        powerKW: Int? = nil,
        odometerHundredthsMile: Int? = nil,
        activeRouteDestination: String? = nil,
        activeRouteMinutesToArrival: Double? = nil,
        activeRouteMilesToArrival: Double? = nil,
        activeRouteTrafficMinutesDelay: Double? = nil,
        activeRouteEnergyAtArrival: Double? = nil,
        activeRouteCoordinates: Coordinate? = nil,
        lastRouteUpdateSecondsSinceEpoch: UInt32? = nil,
        lastTrafficUpdateSecondsSinceEpoch: Int64? = nil,
        timestampSecondsSinceEpoch: Int64? = nil,
    ) {
        self.shiftState = shiftState
        self.speedMph = speedMph
        self.powerKW = powerKW
        self.odometerHundredthsMile = odometerHundredthsMile
        self.activeRouteDestination = activeRouteDestination
        self.activeRouteMinutesToArrival = activeRouteMinutesToArrival
        self.activeRouteMilesToArrival = activeRouteMilesToArrival
        self.activeRouteTrafficMinutesDelay = activeRouteTrafficMinutesDelay
        self.activeRouteEnergyAtArrival = activeRouteEnergyAtArrival
        self.activeRouteCoordinates = activeRouteCoordinates
        self.lastRouteUpdateSecondsSinceEpoch = lastRouteUpdateSecondsSinceEpoch
        self.lastTrafficUpdateSecondsSinceEpoch = lastTrafficUpdateSecondsSinceEpoch
        self.timestampSecondsSinceEpoch = timestampSecondsSinceEpoch
    }
}
