import XCTest
@testable import SoleaCore

final class ExposedZonesTests: XCTestCase {
    func testEmptyZonesExposeNothing() {
        XCTAssertEqual(ExposedZones([]).bodyFraction, 0)
    }

    func testAllZonesFraction() {
        XCTAssertEqual(ExposedZones.all.bodyFraction, 0.95, accuracy: 0.0001)
    }

    func testFractionIsAdditive() {
        let zones: ExposedZones = [.torso, .legs]
        XCTAssertEqual(zones.bodyFraction, 0.18 + 0.36, accuracy: 0.0001)
    }

    func testRawValueRoundTrip() {
        let zones: ExposedZones = [.face, .arms]
        XCTAssertEqual(ExposedZones(rawValue: zones.rawValue), zones)
    }
}
