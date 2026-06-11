import XCTest
@testable import SoleaCore

final class StreaksTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private var today: Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: 10))!
    }

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: today)!
    }

    func testNoRecordsIsZero() {
        XCTAssertEqual(Streaks.currentStreak(records: [], today: today, calendar: calendar), 0)
    }

    func testConsecutiveSmartDays() {
        let records = [
            SessionRecord(day: day(0), fractionOfMED: 0.5, vitaminDIU: 100),
            SessionRecord(day: day(-1), fractionOfMED: 0.3, vitaminDIU: 100),
            SessionRecord(day: day(-2), fractionOfMED: 0.7, vitaminDIU: 100),
        ]
        XCTAssertEqual(Streaks.currentStreak(records: records, today: today, calendar: calendar), 3)
    }

    func testGapBreaksStreak() {
        let records = [
            SessionRecord(day: day(0), fractionOfMED: 0.5, vitaminDIU: 100),
            // niente day(-1)
            SessionRecord(day: day(-2), fractionOfMED: 0.5, vitaminDIU: 100),
        ]
        XCTAssertEqual(Streaks.currentStreak(records: records, today: today, calendar: calendar), 1)
    }

    func testUnsafeDayBreaksStreak() {
        let records = [
            SessionRecord(day: day(0), fractionOfMED: 0.5, vitaminDIU: 100),
            SessionRecord(day: day(-1), fractionOfMED: 0.95, vitaminDIU: 100), // oltre soglia
            SessionRecord(day: day(-2), fractionOfMED: 0.5, vitaminDIU: 100),
        ]
        XCTAssertEqual(Streaks.currentStreak(records: records, today: today, calendar: calendar), 1)
    }

    func testTodayUnsafeMeansZero() {
        let records = [
            SessionRecord(day: day(0), fractionOfMED: 0.9, vitaminDIU: 100),
        ]
        XCTAssertEqual(Streaks.currentStreak(records: records, today: today, calendar: calendar), 0)
    }

    func testMultipleSessionsSameDayOneUnsafe() {
        let records = [
            SessionRecord(day: day(0), fractionOfMED: 0.4, vitaminDIU: 50),
            SessionRecord(day: day(0), fractionOfMED: 0.9, vitaminDIU: 50), // rende il giorno unsafe
        ]
        XCTAssertEqual(Streaks.currentStreak(records: records, today: today, calendar: calendar), 0)
    }
}
