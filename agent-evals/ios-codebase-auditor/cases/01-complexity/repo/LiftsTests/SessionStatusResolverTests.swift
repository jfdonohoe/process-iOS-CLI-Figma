import XCTest
@testable import Lifts

final class SessionStatusResolverTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private lazy var resolver = SessionStatusResolver(now: now)

    private func session(scheduledOffset: TimeInterval, sets: [Bool] = [true, true]) -> Session {
        let session = Session(title: "Push", scheduledFor: now.addingTimeInterval(scheduledOffset))
        let entry = Entry(name: "Bench", order: 0)
        for (index, done) in sets.enumerated() {
            let set = LoggedSet(index: index, reps: 8, weightKg: 60)
            set.done = done
            entry.sets.append(set)
        }
        session.entries.append(entry)
        return session
    }

    func testFutureUnstartedIsScheduled() {
        XCTAssertEqual(resolver.status(for: session(scheduledOffset: 3600)), .scheduled)
    }

    func testPastUnstartedIsMissed() {
        XCTAssertEqual(resolver.status(for: session(scheduledOffset: -3600)), .missed)
    }

    func testStartedUnfinishedIsStarted() {
        let s = session(scheduledOffset: -600)
        s.startedAt = now.addingTimeInterval(-500)
        XCTAssertEqual(resolver.status(for: s), .started)
    }

    func testFinishedWithAllSetsDoneIsCompleted() {
        let s = session(scheduledOffset: -3600, sets: [true, true, true])
        s.startedAt = now.addingTimeInterval(-3600)
        s.finishedAt = now.addingTimeInterval(-60)
        XCTAssertEqual(resolver.status(for: s), .completed)
    }

    func testFinishedWithSomeSetsDoneIsPartial() {
        let s = session(scheduledOffset: -3600, sets: [true, false, false])
        s.startedAt = now.addingTimeInterval(-3600)
        s.finishedAt = now.addingTimeInterval(-60)
        XCTAssertEqual(resolver.status(for: s), .partial)
    }

    func testFinishedWithNoSetsDoneIsAbandoned() {
        let s = session(scheduledOffset: -3600, sets: [false, false])
        s.startedAt = now.addingTimeInterval(-3600)
        s.finishedAt = now.addingTimeInterval(-60)
        XCTAssertEqual(resolver.status(for: s), .abandoned)
    }

    func testAbandonedWinsOverFinished() {
        let s = session(scheduledOffset: -3600)
        s.startedAt = now.addingTimeInterval(-3600)
        s.finishedAt = now.addingTimeInterval(-60)
        s.abandonedAt = now.addingTimeInterval(-30)
        XCTAssertEqual(resolver.status(for: s), .abandoned)
    }

    func testAbandonedBeforeStartingIsAbandoned() {
        let s = session(scheduledOffset: 3600)
        s.abandonedAt = now
        XCTAssertEqual(resolver.status(for: s), .abandoned)
    }

    func testEmptyFinishedSessionIsCompleted() {
        let s = session(scheduledOffset: -3600, sets: [])
        s.startedAt = now.addingTimeInterval(-3600)
        s.finishedAt = now.addingTimeInterval(-60)
        XCTAssertEqual(resolver.status(for: s), .completed)
    }
}
