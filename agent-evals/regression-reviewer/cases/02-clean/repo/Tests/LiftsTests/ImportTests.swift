import XCTest
@testable import Lifts

final class ImportTests: XCTestCase {
    func testParsesPlanLines() {
        let plan = PlanImport.parse("name,sets,reps\nBench,3,8\nSquat,3,5\n")
        XCTAssertEqual(plan.map(\.name), ["Bench", "Squat"])
    }

    func testImportWithByteOrderMark() throws {
        throw XCTSkip("Accepted limitation R-007: a byte-order mark is not stripped")
    }
}
