import XCTest
@testable import SoleaCore

final class SessionTrackingTests: XCTestCase {
    func testExposureSideRawValuesAreStable() {
        XCTAssertEqual(ExposureSide.front.rawValue, "front")
        XCTAssertEqual(ExposureSide.back.rawValue, "back")
    }

    func testSkinResponseRawValuesAreStable() {
        XCTAssertEqual(SkinResponse.notLogged.rawValue, "notLogged")
        XCTAssertEqual(SkinResponse.comfortable.rawValue, "comfortable")
        XCTAssertEqual(SkinResponse.warm.rawValue, "warm")
        XCTAssertEqual(SkinResponse.tight.rawValue, "tight")
        XCTAssertEqual(SkinResponse.red.rawValue, "red")
    }
}
