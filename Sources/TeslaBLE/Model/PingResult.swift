import Foundation

/// Result of a ``VehicleQuery/ping(id:)`` round-trip.
///
/// Mirrors `CarServer_Ping`. The vehicle echoes the `pingID` it received
/// in the request so callers can correlate, and reports its own clock so
/// that latency / clock-skew can be measured.
public struct PingResult: Sendable, Equatable {
    /// Identifier echoed back by the vehicle.
    public var pingID: Int32
    /// Vehicle-local timestamp seconds since the Unix epoch, or `nil` if
    /// not reported.
    public var localTimestampSecondsSinceEpoch: Int64?
    /// Last timestamp the vehicle received from the client side (echoed),
    /// or `nil` if not reported.
    public var lastRemoteTimestampSecondsSinceEpoch: Int64?

    public init(
        pingID: Int32,
        localTimestampSecondsSinceEpoch: Int64? = nil,
        lastRemoteTimestampSecondsSinceEpoch: Int64? = nil,
    ) {
        self.pingID = pingID
        self.localTimestampSecondsSinceEpoch = localTimestampSecondsSinceEpoch
        self.lastRemoteTimestampSecondsSinceEpoch = lastRemoteTimestampSecondsSinceEpoch
    }
}
