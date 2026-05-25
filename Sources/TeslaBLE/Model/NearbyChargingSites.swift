import Foundation

/// Nearby charging sites as seen by the vehicle's navigation system.
///
/// Swift-native projection of `CarServer_NearbyChargingSites` returned by
/// ``VehicleQuery/nearbyCharging(includeMetadata:radiusMiles:count:)``.
public struct NearbyChargingSites: Sendable, Equatable {
    /// Server-side timestamp at which the vehicle generated this snapshot.
    /// Seconds since the Unix epoch. Nil if not reported.
    public var timestampSecondsSinceEpoch: Int64?
    /// Tesla Supercharger sites returned by the vehicle.
    public var superchargers: [Supercharger]
    /// Server-side timestamp of the last congestion (stall-availability)
    /// sync, in seconds since the Unix epoch. 0 when not reported.
    public var congestionSyncTimeSecondsSinceEpoch: Int64

    public init(
        timestampSecondsSinceEpoch: Int64? = nil,
        superchargers: [Supercharger] = [],
        congestionSyncTimeSecondsSinceEpoch: Int64 = 0,
    ) {
        self.timestampSecondsSinceEpoch = timestampSecondsSinceEpoch
        self.superchargers = superchargers
        self.congestionSyncTimeSecondsSinceEpoch = congestionSyncTimeSecondsSinceEpoch
    }

    /// A single Supercharger site reported by the vehicle.
    ///
    /// Mirrors `CarServer_Superchargers`. All fields are non-optional
    /// because they're proto3 scalars without `optional_*` wrapping.
    public struct Supercharger: Sendable, Equatable, Identifiable {
        /// Site identifier as known to Tesla.
        public var id: Int64
        /// Display name of the site.
        public var name: String
        /// Geographic location of the site. Nil if the vehicle did not
        /// include `location` in the report.
        public var location: Coordinate?
        /// Distance from the vehicle's current position, in miles.
        public var distanceMiles: Float
        /// Stalls currently advertised as available. -1 means
        /// "availability unknown".
        public var availableStalls: Int32
        /// Total number of stalls at the site.
        public var totalStalls: Int32
        /// Stalls reported as out-of-order, when available.
        public var outOfOrderStallsNumber: Int32
        /// Comma-separated list of out-of-order stall names, when available.
        public var outOfOrderStallsNames: String
        /// Maximum charging power per stall in kilowatts. 0 if unreported.
        public var maxPowerKw: Int32
        /// Whether the site is closed.
        public var siteClosed: Bool
        /// Whether the site is within the vehicle's current driving range.
        public var withinRange: Bool
        /// Free-form amenities text shown in the in-car UI.
        public var amenities: String
        /// Free-form billing-information text.
        public var billingInfo: String
        /// Free-form billing-time text.
        public var billingTime: String
        /// Street address.
        public var streetAddress: String
        /// City.
        public var city: String
        /// District (administrative region within a city).
        public var district: String
        /// State / province / prefecture.
        public var state: String
        /// Postal code.
        public var postalCode: String
        /// ISO country name as reported by the vehicle.
        public var country: String

        public init(
            id: Int64,
            name: String = "",
            location: Coordinate? = nil,
            distanceMiles: Float = 0,
            availableStalls: Int32 = 0,
            totalStalls: Int32 = 0,
            outOfOrderStallsNumber: Int32 = 0,
            outOfOrderStallsNames: String = "",
            maxPowerKw: Int32 = 0,
            siteClosed: Bool = false,
            withinRange: Bool = false,
            amenities: String = "",
            billingInfo: String = "",
            billingTime: String = "",
            streetAddress: String = "",
            city: String = "",
            district: String = "",
            state: String = "",
            postalCode: String = "",
            country: String = "",
        ) {
            self.id = id
            self.name = name
            self.location = location
            self.distanceMiles = distanceMiles
            self.availableStalls = availableStalls
            self.totalStalls = totalStalls
            self.outOfOrderStallsNumber = outOfOrderStallsNumber
            self.outOfOrderStallsNames = outOfOrderStallsNames
            self.maxPowerKw = maxPowerKw
            self.siteClosed = siteClosed
            self.withinRange = withinRange
            self.amenities = amenities
            self.billingInfo = billingInfo
            self.billingTime = billingTime
            self.streetAddress = streetAddress
            self.city = city
            self.district = district
            self.state = state
            self.postalCode = postalCode
            self.country = country
        }
    }
}
