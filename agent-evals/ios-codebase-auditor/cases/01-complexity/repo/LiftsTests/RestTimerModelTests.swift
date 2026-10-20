import XCTest
@testable import Lifts

final class RestTimerModelTests: XCTestCase {
    func testLabelFormatsEveryRange() {
        let model = RestTimerModel(total: 605)
        XCTAssertEqual(model.label, "10:05")
        for _ in 0..<515 { model.tick() }   // 90 s
        XCTAssertEqual(model.label, "1:30")
        for _ in 0..<75 { model.tick() }    // 15 s
        XCTAssertEqual(model.label, "0:15")
        for _ in 0..<8 { model.tick() }     // 7 s
        XCTAssertEqual(model.label, "0:07")
        for _ in 0..<7 { model.tick() }     // 0 s
        XCTAssertEqual(model.label, "0:00")
    }

    func testTickStopsAtZero() {
        let model = RestTimerModel(total: 2)
        model.start()
        model.tick(); model.tick(); model.tick()
        XCTAssertEqual(model.remaining, 0)
        XCTAssertTrue(model.isFinished)
        XCTAssertFalse(model.isRunning)
    }

    func testIsRunningOnlyBetweenStartAndZero() {
        let model = RestTimerModel(total: 3)
        XCTAssertFalse(model.isRunning)
        model.start()
        XCTAssertTrue(model.isRunning)
        model.tick()
        XCTAssertTrue(model.isRunning)
        model.reset()
        XCTAssertFalse(model.isRunning)
        XCTAssertEqual(model.remaining, 3)
    }
}
