import XCTest
@testable import SoleaCore

final class SafeExposureTests: XCTestCase {
    func testKnownValue() throws {
        // Fototipo II (MED 250), limite prudente 80%, UV 8:
        // 250 × 0.8 / (8 × 0.025 × 60) ≈ 16.7 min
        let minutes = try SafeExposure.minutes(phototype: .typeII, uvIndex: 8)
        XCTAssertEqual(minutes, 200.0 / 12.0, accuracy: 0.01)
    }

    func testSPFIsCappedByReapplicationWindow() throws {
        let protected = try SafeExposure.minutes(phototype: .typeIII, uvIndex: 6, spf: 30)
        XCTAssertEqual(protected, SafeExposure.maximumMinutesPerSunscreenApplication, accuracy: 0.001)
    }

    func testLowerSPFCanStillBeDoseLimitedBeforeReapplication() throws {
        let protected = try SafeExposure.minutes(phototype: .typeI, uvIndex: 8, spf: 6)
        XCTAssertEqual(protected, 60, accuracy: 0.001)
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
        XCTAssertThrowsError(try SafeExposure.minutes(phototype: .typeI, uvIndex: 5, targetDoseFraction: 1.2)) {
            XCTAssertEqual($0 as? SafeExposureError, .invalidTargetDoseFraction(1.2))
        }
        XCTAssertThrowsError(try SafeExposure.minutes(phototype: .typeI, uvIndex: .nan))
        XCTAssertThrowsError(try SafeExposure.dose(uvIndex: 5, minutes: -10)) {
            XCTAssertEqual($0 as? SafeExposureError, .invalidDuration(-10))
        }
    }

    func testRecommendedLimitRoundTripWithoutSunscreen() throws {
        // Esporsi esattamente per il limite prudente produce l'80% della MED.
        for phototype in Fitzpatrick.allCases {
            let uv = 7.0
            let minutes = try SafeExposure.minutes(phototype: phototype, uvIndex: uv)
            let dose = try SafeExposure.dose(uvIndex: uv, minutes: minutes)
            XCTAssertEqual(
                dose,
                SafeExposure.recommendedDoseLimit(phototype: phototype),
                accuracy: 0.001
            )
        }
    }

    func testFullMEDCanStillBeRequestedExplicitly() throws {
        for phototype in Fitzpatrick.allCases {
            let uv = 7.0
            let minutes = try SafeExposure.minutes(
                phototype: phototype,
                uvIndex: uv,
                targetDoseFraction: 1
            )
            let dose = try SafeExposure.dose(uvIndex: uv, minutes: minutes)
            XCTAssertEqual(dose, phototype.med, accuracy: 0.001)
        }
    }

    func testHighPhototypeToleratesMore() throws {
        let timeI = try SafeExposure.minutes(phototype: .typeI, uvIndex: 7)
        let timeVI = try SafeExposure.minutes(phototype: .typeVI, uvIndex: 7)
        XCTAssertEqual(timeVI / timeI, 1000.0 / 150.0, accuracy: 0.001)
    }
}
