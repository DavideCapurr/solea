import XCTest
@testable import SoleaCore

final class BadgeTests: XCTestCase {
    func testNothingUnlockedAtZero() {
        let progress = BadgeProgress(sessionCount: 0, currentStreak: 0, completedPlans: 0, totalVitaminDIU: 0)
        XCTAssertTrue(Badge.unlocked(for: progress).isEmpty)
    }

    func testFirstSession() {
        let progress = BadgeProgress(sessionCount: 1, currentStreak: 1, completedPlans: 0, totalVitaminDIU: 0)
        XCTAssertEqual(Badge.unlocked(for: progress), [.firstSession])
    }

    func testWeekStreakNeedsSevenDays() {
        let six = BadgeProgress(sessionCount: 6, currentStreak: 6, completedPlans: 0, totalVitaminDIU: 0)
        XCTAssertFalse(Badge.unlocked(for: six).contains(.weekStreak))
        let seven = BadgeProgress(sessionCount: 7, currentStreak: 7, completedPlans: 0, totalVitaminDIU: 0)
        XCTAssertTrue(Badge.unlocked(for: seven).contains(.weekStreak))
    }

    func testVitaminDThreshold() {
        let below = BadgeProgress(sessionCount: 3, currentStreak: 1, completedPlans: 0, totalVitaminDIU: 9_999)
        XCTAssertFalse(Badge.unlocked(for: below).contains(.vitaminD10k))
        let at = BadgeProgress(sessionCount: 3, currentStreak: 1, completedPlans: 0, totalVitaminDIU: 10_000)
        XCTAssertTrue(Badge.unlocked(for: at).contains(.vitaminD10k))
    }

    func testAllUnlocked() {
        let progress = BadgeProgress(sessionCount: 10, currentStreak: 7, completedPlans: 2, totalVitaminDIU: 20_000)
        XCTAssertEqual(Badge.unlocked(for: progress), Set(Badge.allCases))
    }

    func testBadgeRawValuesAreStable() {
        // I rawValue sono usati come ID achievement Game Center: non vanno cambiati.
        XCTAssertEqual(Badge.firstSession.rawValue, "firstSession")
        XCTAssertEqual(Badge.weekStreak.rawValue, "weekStreak")
        XCTAssertEqual(Badge.plannerCompleted.rawValue, "plannerCompleted")
        XCTAssertEqual(Badge.vitaminD10k.rawValue, "vitaminD10k")
    }
}
