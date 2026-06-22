import XCTest
@testable import SoleaCore

final class SunExposureAdvisorTests: XCTestCase {
    func testGradualTanStaysBelowSafeExposureLimit() throws {
        let recommendation = try SunExposureAdvisor.recommendation(
            phototype: .typeIII,
            uvIndex: 7,
            goal: .gradualTan
        )
        let safeMinutes = try SafeExposure.minutes(phototype: .typeIII, uvIndex: 7)

        XCTAssertLessThan(recommendation.minutes, safeMinutes)
        XCTAssertLessThanOrEqual(
            recommendation.effectiveDoseJoulesPerSquareMeter,
            SafeExposure.recommendedDoseLimit(phototype: .typeIII)
        )
    }

    func testVitaminDUsesVitaminDTargetAndDefaultZones() throws {
        let recommendation = try SunExposureAdvisor.recommendation(
            phototype: .typeIII,
            uvIndex: 6,
            goal: .vitaminD
        )

        XCTAssertEqual(recommendation.zones, [.face, .arms, .legs])
        XCTAssertEqual(
            recommendation.estimatedVitaminDIU,
            SunExposureAdvisor.targetVitaminDIU,
            accuracy: 1
        )
        XCTAssertLessThanOrEqual(
            recommendation.effectiveDoseJoulesPerSquareMeter,
            Fitzpatrick.typeIII.med * SunExposureAdvisor.vitaminDMaximumFractionOfMED
        )
    }

    func testReachedGoalReturnsZeroMinutes() throws {
        let targetDose = Fitzpatrick.typeII.med * SunExposureAdvisor.lowRiskFractionOfMED
        let recommendation = try SunExposureAdvisor.recommendation(
            phototype: .typeII,
            uvIndex: 5,
            goal: .lowRisk,
            doseAlreadyToday: targetDose
        )

        XCTAssertEqual(recommendation.minutes, 0)
        XCTAssertEqual(recommendation.effectiveDoseJoulesPerSquareMeter, 0)
    }

    func testNegligibleUVReturnsUnlimitedTime() throws {
        let recommendation = try SunExposureAdvisor.recommendation(
            phototype: .typeIV,
            uvIndex: 0.4,
            goal: .gradualTan
        )

        XCTAssertTrue(recommendation.minutes.isInfinite)
        XCTAssertEqual(recommendation.estimatedVitaminDIU, 0)
    }

    func testRecommendedPlanBlocksDirectSunForRedSkin() throws {
        let recommendation = try SunExposureAdvisor.recommendedPlan(
            phototype: .typeIV,
            uvIndex: 5,
            skinResponse: .red
        )

        XCTAssertEqual(recommendation.goal, .lowRisk)
        XCTAssertEqual(recommendation.minutes, 0)
        XCTAssertEqual(recommendation.effectiveDoseJoulesPerSquareMeter, 0)
    }

    func testRecommendedGoalUsesSkinTypeAndCurrentUV() throws {
        let fairSkinHighUV = try SunExposureAdvisor.recommendedGoal(
            phototype: .typeII,
            uvIndex: 6
        )
        let oliveSkinModerateUV = try SunExposureAdvisor.recommendedGoal(
            phototype: .typeIV,
            uvIndex: 5
        )

        XCTAssertEqual(fairSkinHighUV, .lowRisk)
        XCTAssertEqual(oliveSkinModerateUV, .gradualTan)
    }

    func testWarmSkinReducesRecommendedDose() throws {
        let comfortable = try SunExposureAdvisor.recommendation(
            phototype: .typeIII,
            uvIndex: 5,
            goal: .gradualTan,
            skinResponse: .comfortable
        )
        let warm = try SunExposureAdvisor.recommendation(
            phototype: .typeIII,
            uvIndex: 5,
            goal: .gradualTan,
            skinResponse: .warm
        )

        XCTAssertLessThan(warm.effectiveDoseJoulesPerSquareMeter, comfortable.effectiveDoseJoulesPerSquareMeter)
    }

    func testInvalidInputsThrow() {
        XCTAssertThrowsError(try SunExposureAdvisor.recommendation(
            phototype: .typeIII,
            uvIndex: .nan,
            goal: .gradualTan
        )) {
            guard case .invalidUVIndex(let value) = $0 as? SunExposureAdvisorError else {
                return XCTFail("Expected invalid UV index error")
            }
            XCTAssertTrue(value.isNaN)
        }

        XCTAssertThrowsError(try SunExposureAdvisor.recommendation(
            phototype: .typeIII,
            uvIndex: 5,
            goal: .gradualTan,
            doseAlreadyToday: -1
        )) {
            XCTAssertEqual($0 as? SunExposureAdvisorError, .invalidDoseAlreadyToday(-1))
        }
    }
}
