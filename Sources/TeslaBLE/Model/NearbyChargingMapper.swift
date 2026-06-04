import Foundation

/// Internal bridge from `CarServer_NearbyChargingSites` to the public
/// Swift-native ``NearbyChargingSites``.
///
/// Sibling of ``VehicleSnapshotMapper`` and ``VCSECStatusMapper`` —
/// kept in `Sources/TeslaBLE/Model/` so `CarServer_*` protobuf imports
/// stay confined to mapper files.
enum NearbyChargingMapper {
    static func map(_ pb: CarServer_NearbyChargingSites) -> NearbyChargingSites {
        NearbyChargingSites(
            timestampSecondsSinceEpoch: pb.hasTimestamp ? pb.timestamp.seconds : nil,
            superchargers: pb.superchargers.map(mapSupercharger(_:)),
            congestionSyncTimeSecondsSinceEpoch: pb.congestionSyncTimeUtcSecs,
        )
    }

    private static func mapSupercharger(
        _ pb: CarServer_Superchargers,
    ) -> NearbyChargingSites.Supercharger {
        NearbyChargingSites.Supercharger(
            id: pb.id,
            name: pb.name,
            location: pb.hasLocation
                ? Coordinate(
                    latitude: Double(pb.location.latitude),
                    longitude: Double(pb.location.longitude),
                )
                : nil,
            distanceMiles: pb.distanceMiles,
            availableStalls: pb.availableStalls,
            totalStalls: pb.totalStalls,
            outOfOrderStallsNumber: pb.outOfOrderStallsNumber,
            outOfOrderStallsNames: pb.outOfOrderStallsNames,
            maxPowerKw: pb.maxPowerKw,
            siteClosed: pb.siteClosed,
            withinRange: pb.withinRange,
            amenities: pb.amenities,
            billingInfo: pb.billingInfo,
            billingTime: pb.billingTime,
            streetAddress: pb.streetAddress,
            city: pb.city,
            district: pb.district,
            state: pb.state,
            postalCode: pb.postalCode,
            country: pb.country,
        )
    }
}
