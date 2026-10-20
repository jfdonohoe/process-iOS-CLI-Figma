import XCTest
@testable import Lifts

final class CorrectionTests: XCTestCase {
    private let day = Date(timeIntervalSince1970: 1_700_000_000)

    func testCorrectionIsAppendedAndLoggedValueKept() throws {
        let store = SessionStore()
        let session = store.schedule(store.addRoutine(name: "Push", exercises: []), for: day)
        try store.log(SetEntry(exercise: "Bench", reps: 8, done: true), in: session)
        store.finish(session, at: day)
        let entry = session.entries[0]
        try store.correct(session, entryID: entry.id, reps: 9, at: day)
        XCTAssertEqual(session.corrections.count, 1)
        XCTAssertEqual(session.entries[0].reps, 8)
        XCTAssertEqual(store.effectiveReps(session.entries[0], in: session), 9)
    }

    func testCorrectingAnOpenSessionIsRefused() throws {
        let store = SessionStore()
        let session = store.schedule(store.addRoutine(name: "Push", exercises: []), for: day)
        try store.log(SetEntry(exercise: "Bench", reps: 8), in: session)
        XCTAssertThrowsError(try store.correct(session, entryID: session.entries[0].id, reps: 9)) { error in
            XCTAssertEqual(error as? StoreError, .notLocked)
        }
    }

    func testUnknownEntryIsRefused() throws {
        let store = SessionStore()
        let session = store.schedule(store.addRoutine(name: "Push", exercises: []), for: day)
        store.finish(session, at: day)
        XCTAssertThrowsError(try store.correct(session, entryID: UUID(), reps: 9)) { error in
            XCTAssertEqual(error as? StoreError, .unknownEntry)
        }
    }
}
