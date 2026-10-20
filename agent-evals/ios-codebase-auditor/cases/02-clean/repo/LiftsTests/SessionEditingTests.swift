import XCTest
import SwiftData
@testable import Lifts

@MainActor
final class SessionEditingTests: XCTestCase {
    private var context: ModelContext!

    override func setUpWithError() throws {
        let container = try ModelContainer(for: Schema.lifts,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        context = ModelContext(container)
    }

    private func session(sets: Int = 2) -> Session {
        let session = makeSession(on: .now, sets: Array(repeating: false, count: sets))
        context.insert(session)
        return session
    }

    func testFinishStampsStartAndFinishAndLocks() throws {
        let s = session()
        let now = Date(timeIntervalSince1970: 1_000_000)
        try SessionEditing.finish(s, in: context, now: now)
        XCTAssertEqual(s.startedAt, now)
        XCTAssertEqual(s.finishedAt, now)
        XCTAssertTrue(s.isLocked)
    }

    func testFinishKeepsAnEarlierStart() throws {
        let s = session()
        let started = Date(timeIntervalSince1970: 900_000)
        s.startedAt = started
        try SessionEditing.finish(s, in: context, now: Date(timeIntervalSince1970: 1_000_000))
        XCTAssertEqual(s.startedAt, started)
    }

    func testToggleTicksAndUnticksASet() throws {
        let s = session()
        let set = s.orderedSets.first!
        try SessionEditing.toggle(set, in: context)
        XCTAssertTrue(set.done)
        XCTAssertEqual(s.doneSetCount, 1)
        try SessionEditing.toggle(set, in: context)
        XCTAssertFalse(set.done)
    }

    func testALockedSessionIsNeverWritten() throws {
        let s = session()
        try SessionEditing.finish(s, in: context)
        let finishedAt = s.finishedAt
        let set = s.orderedSets.first!
        XCTAssertThrowsError(try SessionEditing.toggle(set, in: context)) {
            XCTAssertEqual($0 as? SessionEditing.Failure, .sessionIsLocked)
        }
        XCTAssertThrowsError(try SessionEditing.finish(s, in: context))
        XCTAssertFalse(set.done)
        XCTAssertEqual(s.finishedAt, finishedAt)
    }
}

private extension Session {
    var orderedSets: [LoggedSet] { orderedEntries.flatMap(\.orderedSets) }
}
