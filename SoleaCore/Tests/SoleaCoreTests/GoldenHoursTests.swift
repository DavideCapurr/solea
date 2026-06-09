import XCTest
@testable import SoleaCore

final class GoldenHoursTests: XCTestCase {
    private func makeForecast(startHour: Int, uvValues: [Double]) -> [UVHour] {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(
            from: DateComponents(year: 2026, month: 6, day: 9, hour: startHour)
        )!
        return uvValues.enumerated().map { offset, uv in
            UVHour(date: start.addingTimeInterval(Double(offset) * 3600), uvIndex: uv)
        }
    }

    func testContiguousHoursAreMerged() {
        // Dalle 8: UV 1, 3, 4, 5, 3, 1 → per fototipo III (cap 7) finestra 9–13.
        let forecast = makeForecast(startHour: 8, uvValues: [1, 3, 4, 5, 3, 1])
        let windows = GoldenHours.windows(in: forecast, phototype: .typeIII)
        XCTAssertEqual(windows.count, 1)
        XCTAssertEqual(windows[0].duration, 4 * 3600)
        XCTAssertEqual(Calendar(identifier: .gregorian).component(.hour, from: windows[0].start), 9)
    }

    func testMiddayPeakSplitsWindowForFairSkin() {
        // UV 3, 4, 6, 8, 8, 6, 4, 3: per fototipo I (cap 5) restano due finestre
        // (mattina e tardo pomeriggio), il picco è escluso.
        let forecast = makeForecast(startHour: 9, uvValues: [3, 4, 6, 8, 8, 6, 4, 3])
        let windows = GoldenHours.windows(in: forecast, phototype: .typeI)
        XCTAssertEqual(windows.count, 2)
        XCTAssertEqual(windows[0].duration, 2 * 3600)
        XCTAssertEqual(windows[1].duration, 2 * 3600)
    }

    func testDarkSkinKeepsPeak() {
        // Stesso scenario: per fototipo VI (cap 10) è un'unica finestra di 8 ore.
        let forecast = makeForecast(startHour: 9, uvValues: [3, 4, 6, 8, 8, 6, 4, 3])
        let windows = GoldenHours.windows(in: forecast, phototype: .typeVI)
        XCTAssertEqual(windows.count, 1)
        XCTAssertEqual(windows[0].duration, 8 * 3600)
    }

    func testNoUsefulUVMeansNoWindows() {
        let forecast = makeForecast(startHour: 8, uvValues: [0, 1, 2, 1, 0])
        XCTAssertTrue(GoldenHours.windows(in: forecast, phototype: .typeIII).isEmpty)
    }

    func testUnsortedForecastIsHandled() {
        let forecast = makeForecast(startHour: 10, uvValues: [3, 4, 3]).shuffled()
        let windows = GoldenHours.windows(in: forecast, phototype: .typeII)
        XCTAssertEqual(windows.count, 1)
        XCTAssertEqual(windows[0].duration, 3 * 3600)
    }
}
