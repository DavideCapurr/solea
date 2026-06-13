import XCTest
@testable import SoleaCore

final class BurnRiskTests: XCTestCase {
    func testFreshSkinLowUV() {
        XCTAssertEqual(
            BurnRisk.level(doseTodayJoulesPerSquareMeter: 0, phototype: .typeIII, currentUVIndex: 2),
            .low
        )
    }

    func testModerateUVAloneIsModerate() {
        XCTAssertEqual(
            BurnRisk.level(doseTodayJoulesPerSquareMeter: 0, phototype: .typeIII, currentUVIndex: 6),
            .moderate
        )
    }

    func testVeryHighUVAloneIsHigh() {
        XCTAssertEqual(
            BurnRisk.level(doseTodayJoulesPerSquareMeter: 0, phototype: .typeIII, currentUVIndex: 8),
            .high
        )
    }

    func testNearMEDIsHigh() {
        let dose = Fitzpatrick.typeII.med * SafeExposure.recommendedLimitFractionOfMED
        XCTAssertEqual(
            BurnRisk.level(doseTodayJoulesPerSquareMeter: dose, phototype: .typeII, currentUVIndex: 2),
            .high
        )
    }

    func testExtremeUVWithPartialDoseIsHigh() {
        let dose = Fitzpatrick.typeIII.med * 0.4
        XCTAssertEqual(
            BurnRisk.level(doseTodayJoulesPerSquareMeter: dose, phototype: .typeIII, currentUVIndex: 9),
            .high
        )
    }

    func testPartialDoseIsModerate() {
        let dose = Fitzpatrick.typeIV.med * 0.5
        XCTAssertEqual(
            BurnRisk.level(doseTodayJoulesPerSquareMeter: dose, phototype: .typeIV, currentUVIndex: 3),
            .moderate
        )
    }

    func testNegativeDoseIsClampedToZero() {
        XCTAssertEqual(
            BurnRisk.level(doseTodayJoulesPerSquareMeter: -50, phototype: .typeI, currentUVIndex: 1),
            .low
        )
    }
}
