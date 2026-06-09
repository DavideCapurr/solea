import XCTest
@testable import SoleaCore

final class SafeExposureTests: XCTestCase {
    func testKnownValue() throws {
        // Fototipo II (MED 250), UV 8: 250 / (8 × 0.025 × 60) ≈ 20.8 min
        let minutes = try SafeExposure.minutes(phototype: .typeII, uvIndex: 8)
        XCTAssertEqual(minutes, 250.0 / 12.0, accuracy: 0.01)
    }

    func testSPFMultipliesTime() throws {
        let bare = try SafeExposure.minutes(phototype: .typeIII, uvIndex: 6)
        let protected = try SafeExposure.minutes(phototype: .typeIII, uvIndex: 6, spf: 30)
        XCTAssertEqual(protected, bare * 30, accuracy: 0.001)
    }

    func testNegligibleUVIsUnlimited() throws {
        XCTAssertTrue(try SafeExposure.minutes(phototype: .typeI, uvIndex: 0).isInfinite)
        XCTAssertTrue(try SafeExposure.minutes(phototype: .typeI, uvIndex: 0.5).isInfinite)
        XCTAssertFalse(try SafeExposure.minutes(phototype: .typeI, uvIndex: 0.6).isInfinite)
    }

    func testInvalidInputsThrow() {
        XCTAssertThrowsError(try SafeExposure.minutes(phototype: .typeI, uvIndex: -1)) {
            XCTAssertEqual($0 as? SafeExposureError, .invalidUVIndex(-1))
        }
        XCTAssertThrowsError(try SafeExposure.minutes(phototype: .typeI, uvIndex: 5, spf: 0.5)) {
            XCTAssertEqual($0 as? SafeExposureError, .invalidSPF(0.5))
        }
        XCTAssertThrowsError(try SafeExposure.minutes(phototype: .typeI, uvIndex: .nan))
        XCTAssertThrowsError(try SafeExposure.dose(uvIndex: 5, minutes: -10)) {
            XCTAssertEqual($0 as? SafeExposureError, .invalidDuration(-10))
        }
    }

    func testDoseRoundTrip() throws {
        // Esporsi esattamente per il tempo sicuro deve produrre una dose pari alla MED.
        for phototype in Fitzpatrick.allCases {
            for spf in [1.0, 15.0, 50.0] {
                let uv = 7.0
                let minutes = try SafeExposure.minutes(phototype: phototype, uvIndex: uv, spf: spf)
                let dose = try SafeExposure.dose(uvIndex: uv, minutes: minutes, spf: spf)
                XCTAssertEqual(dose, phototype.med, accuracy: 0.001)
            }
        }
    }

    func testHighPhototypeToleratesMore() throws {
        let timeI = try SafeExposure.minutes(phototype: .typeI, uvIndex: 7)
        let timeVI = try SafeExposure.minutes(phototype: .typeVI, uvIndex: 7)
        XCTAssertEqual(timeVI / timeI, 5, accuracy: 0.001) // MED 1000 vs 200
    }
}
