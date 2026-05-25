import XCTest
import SwiftProtobuf
@testable import TeslaBLE

final class NearbyChargingMapperTests: XCTestCase {
    func testMapsAllFields() {
        var loc = CarServer_LatLong()
        loc.latitude = 37.4419
        loc.longitude = -122.1430

        var sc = CarServer_Superchargers()
        sc.id = 12345
        sc.name = "Palo Alto"
        sc.location = loc
        sc.distanceMiles = 1.2
        sc.availableStalls = 6
        sc.totalStalls = 8
        sc.outOfOrderStallsNumber = 1
        sc.outOfOrderStallsNames = "stall-3"
        sc.maxPowerKw = 250
        sc.siteClosed = false
        sc.withinRange = true
        sc.amenities = "restrooms"
        sc.streetAddress = "300 El Camino Real"
        sc.city = "Palo Alto"
        sc.district = "Stanford"
        sc.state = "CA"
        sc.postalCode = "94306"
        sc.country = "US"

        var sites = CarServer_NearbyChargingSites()
        sites.superchargers = [sc]
        sites.congestionSyncTimeUtcSecs = 1_730_000_900
        var ts = SwiftProtobuf.Google_Protobuf_Timestamp()
        ts.seconds = 1_730_000_500
        sites.timestamp = ts

        let result = NearbyChargingMapper.map(sites)

        XCTAssertEqual(result.timestampSecondsSinceEpoch, 1_730_000_500)
        XCTAssertEqual(result.congestionSyncTimeSecondsSinceEpoch, 1_730_000_900)
        XCTAssertEqual(result.superchargers.count, 1)

        let mapped = result.superchargers[0]
        XCTAssertEqual(mapped.id, 12345)
        XCTAssertEqual(mapped.name, "Palo Alto")
        XCTAssertEqual(mapped.location?.latitude ?? 0, 37.4419, accuracy: 0.0001)
        XCTAssertEqual(mapped.location?.longitude ?? 0, -122.1430, accuracy: 0.0001)
        XCTAssertEqual(mapped.distanceMiles, 1.2, accuracy: 0.001)
        XCTAssertEqual(mapped.availableStalls, 6)
        XCTAssertEqual(mapped.totalStalls, 8)
        XCTAssertEqual(mapped.outOfOrderStallsNumber, 1)
        XCTAssertEqual(mapped.outOfOrderStallsNames, "stall-3")
        XCTAssertEqual(mapped.maxPowerKw, 250)
        XCTAssertFalse(mapped.siteClosed)
        XCTAssertTrue(mapped.withinRange)
        XCTAssertEqual(mapped.amenities, "restrooms")
        XCTAssertEqual(mapped.streetAddress, "300 El Camino Real")
        XCTAssertEqual(mapped.city, "Palo Alto")
        XCTAssertEqual(mapped.district, "Stanford")
        XCTAssertEqual(mapped.state, "CA")
        XCTAssertEqual(mapped.postalCode, "94306")
        XCTAssertEqual(mapped.country, "US")
    }

    func testEmptyResponse() {
        let pb = CarServer_NearbyChargingSites()
        let result = NearbyChargingMapper.map(pb)
        XCTAssertNil(result.timestampSecondsSinceEpoch)
        XCTAssertEqual(result.congestionSyncTimeSecondsSinceEpoch, 0)
        XCTAssertTrue(result.superchargers.isEmpty)
    }

    func testSuperchargerWithoutLocation() {
        var sc = CarServer_Superchargers()
        sc.id = 1
        sc.name = "No-loc site"
        var sites = CarServer_NearbyChargingSites()
        sites.superchargers = [sc]
        let result = NearbyChargingMapper.map(sites)
        XCTAssertNil(result.superchargers[0].location)
    }
}
