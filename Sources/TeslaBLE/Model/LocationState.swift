import Foundation

/// GPS and geocoded position reported by the vehicle.
///
/// Mirrors `CarServer_LocationState` from the upstream Go SDK
/// (`pkg/protocol/protobuf/vehicle.proto`). Every field is optional because
/// the vehicle reports each value via a oneof — an absent value stays `nil`
/// rather than being defaulted to `0`.
public struct LocationState: Sendable, Equatable {
    /// Primary latitude in decimal degrees.
    public var latitude: Double?
    /// Primary longitude in decimal degrees.
    public var longitude: Double?
    /// Heading in degrees clockwise from true north, 0–359.
    public var headingDegrees: Double?
    /// GPS fix timestamp as seconds since the Unix epoch.
    public var gpsAsOfSecondsSinceEpoch: UInt64?
    /// Vehicle-corrected latitude (typically post-snap-to-road).
    public var correctedLatitude: Double?
    /// Vehicle-corrected longitude.
    public var correctedLongitude: Double?
    /// Raw GPS receiver latitude before correction.
    public var nativeLatitude: Double?
    /// Raw GPS receiver longitude before correction.
    public var nativeLongitude: Double?
    /// True if a paired Homelink device is in range.
    public var homelinkNearby: Bool?
    /// Human-readable name of the current location, when known.
    public var locationName: String?
    /// Geocoded latitude (e.g. map-matched).
    public var geoLatitude: Double?
    /// Geocoded longitude.
    public var geoLongitude: Double?
    /// Geocoded heading in degrees.
    public var geoHeadingDegrees: Double?
    /// Geocoded elevation in meters above sea level.
    public var geoElevationMeters: Double?
    /// Geocoded position accuracy radius in meters (lower is better).
    public var geoAccuracyMeters: Double?
    /// True if the vehicle's dead-reckoning estimate is currently valid.
    public var estimatedGpsValid: Bool?

    public init(
        latitude: Double? = nil,
        longitude: Double? = nil,
        headingDegrees: Double? = nil,
        gpsAsOfSecondsSinceEpoch: UInt64? = nil,
        correctedLatitude: Double? = nil,
        correctedLongitude: Double? = nil,
        nativeLatitude: Double? = nil,
        nativeLongitude: Double? = nil,
        homelinkNearby: Bool? = nil,
        locationName: String? = nil,
        geoLatitude: Double? = nil,
        geoLongitude: Double? = nil,
        geoHeadingDegrees: Double? = nil,
        geoElevationMeters: Double? = nil,
        geoAccuracyMeters: Double? = nil,
        estimatedGpsValid: Bool? = nil,
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.headingDegrees = headingDegrees
        self.gpsAsOfSecondsSinceEpoch = gpsAsOfSecondsSinceEpoch
        self.correctedLatitude = correctedLatitude
        self.correctedLongitude = correctedLongitude
        self.nativeLatitude = nativeLatitude
        self.nativeLongitude = nativeLongitude
        self.homelinkNearby = homelinkNearby
        self.locationName = locationName
        self.geoLatitude = geoLatitude
        self.geoLongitude = geoLongitude
        self.geoHeadingDegrees = geoHeadingDegrees
        self.geoElevationMeters = geoElevationMeters
        self.geoAccuracyMeters = geoAccuracyMeters
        self.estimatedGpsValid = estimatedGpsValid
    }
}
