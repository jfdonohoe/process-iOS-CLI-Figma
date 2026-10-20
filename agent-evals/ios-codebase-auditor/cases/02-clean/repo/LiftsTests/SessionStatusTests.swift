import XCTest
@testable import Lifts

final class SessionStatusTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func session(scheduledOffset: TimeInterval, sets: [Bool] = [true, true]) -> Session {
        makeSession(on: now.addingTimeInterval(scheduledOffset), sets: sets)
    }

    func testFutureUnstartedIsScheduled() {
        XCTAssertEqual(session(scheduledOffset: 3600).status(at: now), .scheduled)
    }

    func testPastUnstartedIsMissed() {
        XCTAssertEqual(session(scheduledOffset: -3600).status(at: now), .missed)
    }

    func testStartedUnfinishedIsStarted() {
        let s = session(scheduledOffset: -600)
        s.startedAt = now.addingTimeInterval(-500)
        XCTAssertEqual(s.status(at: now), .started)
    }

    func testFinishedWithAllSetsDoneIsCompleted() {
        let s = session(scheduledOffset: -3600, sets: [true, true, true])
        s.startedAt = now.addingTimeInterval(-3600)
        s.finishedAt = now.addingTimeInterval(-60)
        XCTAssertEqual(s.status(at: now), .completed)
    }

    func testFinishedWithSomeSetsDoneIsPartial() {
        let s = session(scheduledOffset: -3600, sets: [true, false, false])
        s.startedAt = now.addingTimeInterval(-3600)
        s.finishedAt = now.addingTimeInterval(-60)
        XCTAssertEqual(s.status(at: now), .partial)
    }

    func testFinishedWithNoSetsDoneIsAbandoned() {
        let s = session(scheduledOffset: -3600, sets: [false, false])
        s.startedAt = now.addingTimeInterval(-3600)
        s.finishedAt = now.addingTimeInterval(-60)
        XCTAssertEqual(s.status(at: now), .abandoned)
    }

    func testAbandonedWinsOverFinished() {
        let s = session(scheduledOffset: -3600)
        s.startedAt = now.addingTimeInterval(-3600)
        s.finishedAt = now.addingTimeInterval(-60)
        s.abandonedAt = now.addingTimeInterval(-30)
        XCTAssertEqual(s.status(at: now), .abandoned)
    }

    func testEmptyFinishedSessionIsCompleted() {
        let s = session(scheduledOffset: -3600, sets: [])
        s.startedAt = now.addingTimeInterval(-3600)
        s.finishedAt = now.addingTimeInterval(-60)
        XCTAssertEqual(s.status(at: now), .completed)
    }
}
