import XCTest
@testable import Lifts

final class ImportTests: XCTestCase {
    func testParsesPlanLines() {
        let plan = PlanImport.parse("name,sets,reps\nBench,3,8\nSquat,3,5\n")
        XCTAssertEqual(plan.map(\.name), ["Bench", "Squat"])
        XCTAssertEqual(plan.map(\.reps), [8, 5])
    }

    func testSkipsLinesThatDoNotParse() {
        let plan = PlanImport.parse("Bench,3\n\nSquat,three,5\nRow,1,1\n")
        XCTAssertEqual(plan.map(\.name), ["Row"])
    }
}
