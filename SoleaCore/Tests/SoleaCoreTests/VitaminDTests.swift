import XCTest
@testable import SoleaCore

final class VitaminDTests: XCTestCase {
    func testZeroDoseProducesNothing() {
        XCTAssertEqual(
            VitaminD.estimatedIU(effectiveDoseJoulesPerSquareMeter: 0, phototype: .typeIII, zones: .all),
            0
        )
    }

    func testOneMEDFullBodyFairSkin() {
        // Fototipo II, una MED intera, tutto il corpo: 15000 × 0.95 × 1.0
        let iu = VitaminD.estimatedIU(
            effectiveDoseJoulesPerSquareMeter: Fitzpatrick.typeII.med,
            phototype: .typeII,
            zones: .all
        )
        XCTAssertEqual(iu, 15_000 * 0.95, accuracy: 0.001)
    }

    func testDarkerSkinSynthesizesLess() {
        let fair = VitaminD.estimatedIU(
            effectiveDoseJoulesPerSquareMeter: 100, phototype: .typeII, zones: .all
        )
        // A parità di frazione di MED il fototipo VI sintetizza il 30%.
        let dark = VitaminD.estimatedIU(
            effectiveDoseJoulesPerSquareMeter: 100 * Fitzpatrick.typeVI.med / Fitzpatrick.typeII.med,
            phototype: .typeVI,
            zones: .all
        )
        XCTAssertEqual(dark / fair, 0.3, accuracy: 0.001)
    }

    func testFewerZonesProduceLess() {
        let all = VitaminD.estimatedIU(
            effectiveDoseJoulesPerSquareMeter: 200, phototype: .typeIII, zones: .all
        )
        let faceOnly = VitaminD.estimatedIU(
            effectiveDoseJoulesPerSquareMeter: 200, phototype: .typeIII, zones: .face
        )
        XCTAssertEqual(faceOnly / all, 0.05 / 0.95, accuracy: 0.001)
    }

    func testSaturationCap() {
        let iu = VitaminD.estimatedIU(
            effectiveDoseJoulesPerSquareMeter: 100_000, phototype: .typeI, zones: .all
        )
        XCTAssertEqual(iu, VitaminD.dailySaturationIU)
    }
}
