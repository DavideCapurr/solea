import XCTest
@testable import SoleaCore

final class TanPlannerTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private var startDate: Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
    }

    func testPlanHasOneEntryPerDay() throws {
        let plan = try TanPlanner.plan(
            phototype: .typeIII,
            preparationDays: 10,
            expectedUVIndex: 8,
            startingFrom: startDate,
            calendar: calendar
        )
        XCTAssertEqual(plan.count, 10)
        XCTAssertEqual(plan.map(\.id), Array(0..<10))
    }

    func testMinutesIncreaseOverTime() throws {
        let plan = try TanPlanner.plan(
            phototype: .typeII,
            preparationDays: 14,
            expectedUVIndex: 7,
            startingFrom: startDate,
            calendar: calendar
        )
        for (earlier, later) in zip(plan, plan.dropFirst()) {
            XCTAssertLessThanOrEqual(earlier.minutes, later.minutes)
        }
    }

    func testMinutesAreCapped() throws {
        let plan = try TanPlanner.plan(
            phototype: .typeVI,
            preparationDays: 30,
            expectedUVIndex: 11,
            startingFrom: startDate,
            calendar: calendar
        )
        for day in plan {
            XCTAssertLessThanOrEqual(day.minutes, TanPlanner.maximumDailyMinutes)
        }
    }

    func testSPFDecreasesAndRespectsFloor() throws {
        let plan = try TanPlanner.plan(
            phototype: .typeI,
            preparationDays: 12,
            expectedUVIndex: 6,
            startingFrom: startDate,
            calendar: calendar
        )
        let range = TanPlanner.spfRange(for: .typeI)
        XCTAssertEqual(plan.first?.spf, range.start)
        XCTAssertEqual(plan.last?.spf, range.end)
        for (earlier, later) in zip(plan, plan.dropFirst()) {
            XCTAssertGreaterThanOrEqual(earlier.spf, later.spf)
            XCTAssertGreaterThanOrEqual(later.spf, range.end)
        }
    }

    func testConsecutiveDates() throws {
        let plan = try TanPlanner.plan(
            phototype: .typeIV,
            preparationDays: 5,
            expectedUVIndex: 9,
            startingFrom: startDate,
            calendar: calendar
        )
        for (earlier, later) in zip(plan, plan.dropFirst()) {
            let days = calendar.dateComponents([.day], from: earlier.date, to: later.date).day
            XCTAssertEqual(days, 1)
        }
    }

    func testSingleDayPlan() throws {
        let plan = try TanPlanner.plan(
            phototype: .typeIII,
            preparationDays: 1,
            expectedUVIndex: 8,
            startingFrom: startDate,
            calendar: calendar
        )
        XCTAssertEqual(plan.count, 1)
        XCTAssertEqual(plan[0].spf, TanPlanner.spfRange(for: .typeIII).end)
    }

    func testInvalidInputsThrow() {
        XCTAssertThrowsError(try TanPlanner.plan(
            phototype: .typeIII, preparationDays: 0, expectedUVIndex: 8, startingFrom: startDate
        )) {
            XCTAssertEqual($0 as? TanPlannerError, .invalidPreparationDays(0))
        }
        XCTAssertThrowsError(try TanPlanner.plan(
            phototype: .typeIII, preparationDays: 100, expectedUVIndex: 8, startingFrom: startDate
        ))
        XCTAssertThrowsError(try TanPlanner.plan(
            phototype: .typeIII, preparationDays: 10, expectedUVIndex: 0, startingFrom: startDate
        )) {
            XCTAssertEqual($0 as? TanPlannerError, .invalidUVIndex(0))
        }
        XCTAssertThrowsError(try TanPlanner.plan(
            phototype: .typeIII, preparationDays: 10, expectedUVIndex: .nan, startingFrom: startDate
        ))
    }
}
