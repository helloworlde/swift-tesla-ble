import Foundation

/// A simple latitude/longitude pair in WGS-84 decimal degrees.
///
/// Mirrors `CarServer_LatLong` from the upstream Go SDK; reused for any
/// vehicle-reported location (home, work, route destination, etc.).
public struct Coordinate: Sendable, Equatable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
