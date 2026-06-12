import XCTest
@testable import SoleaCore

final class FitzpatrickQuizTests: XCTestCase {
    func testQuizStructure() {
        XCTAssertEqual(FitzpatrickQuiz.questions.count, 6)
        for question in FitzpatrickQuiz.questions {
            XCTAssertEqual(question.options.count, 5, "Domanda \(question.id) deve avere 5 opzioni")
            XCTAssertEqual(question.options.map(\.score), [0, 1, 2, 3, 4])
        }
        XCTAssertEqual(FitzpatrickQuiz.maximumScore, 24)
    }

    func testScoreExtremes() {
        XCTAssertEqual(FitzpatrickQuiz.phototype(totalScore: 0), .typeI)
        XCTAssertEqual(FitzpatrickQuiz.phototype(totalScore: FitzpatrickQuiz.maximumScore), .typeVI)
    }

    func testThresholds() {
        XCTAssertEqual(FitzpatrickQuiz.phototype(totalScore: 3), .typeI)
        XCTAssertEqual(FitzpatrickQuiz.phototype(totalScore: 4), .typeII)
        XCTAssertEqual(FitzpatrickQuiz.phototype(totalScore: 7), .typeII)
        XCTAssertEqual(FitzpatrickQuiz.phototype(totalScore: 8), .typeIII)
        XCTAssertEqual(FitzpatrickQuiz.phototype(totalScore: 12), .typeIII)
        XCTAssertEqual(FitzpatrickQuiz.phototype(totalScore: 13), .typeIV)
        XCTAssertEqual(FitzpatrickQuiz.phototype(totalScore: 16), .typeIV)
        XCTAssertEqual(FitzpatrickQuiz.phototype(totalScore: 17), .typeV)
        XCTAssertEqual(FitzpatrickQuiz.phototype(totalScore: 20), .typeV)
        XCTAssertEqual(FitzpatrickQuiz.phototype(totalScore: 21), .typeVI)
    }

    func testPhototypeIsMonotonicInScore() {
        var previous = FitzpatrickQuiz.phototype(totalScore: 0)
        for score in 1...FitzpatrickQuiz.maximumScore {
            let current = FitzpatrickQuiz.phototype(totalScore: score)
            XCTAssertGreaterThanOrEqual(current.rawValue, previous.rawValue)
            previous = current
        }
    }

    func testMEDIsMonotonicInPhototype() {
        let meds = Fitzpatrick.allCases.map(\.med)
        XCTAssertEqual(meds, meds.sorted())
        XCTAssertEqual(Fitzpatrick.typeI.med, 150)
        XCTAssertEqual(Fitzpatrick.typeVI.med, 1000)
    }
}
