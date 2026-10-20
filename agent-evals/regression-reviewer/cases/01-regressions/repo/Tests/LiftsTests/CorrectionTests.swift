import XCTest
@testable import Lifts

final class CorrectionTests: XCTestCase {
    private func lockedSession(_ store: SessionStore, reps: Int) throws -> (Session, SetEntry) {
        let session = store.start(store.addRoutine(name: "Push", exercises: []))
        let entry = SetEntry(exercise: "Bench", reps: reps)
        try store.log(entry, in: session)
        store.finish(session)
        return (session, entry)
    }

    func testCorrectionIsRecorded() throws {
        let store = SessionStore()
        let (session, entry) = try lockedSession(store, reps: 8)
        try store.correct(session, entryID: entry.id, reps: 10)
        XCTAssertEqual(session.corrections.count, 1)
        XCTAssertEqual(store.effectiveReps(session.entries[0], in: session), 10)
    }

    func testCorrectionRequiresLockedSession() throws {
        let store = SessionStore()
        let session = store.start(store.addRoutine(name: "Push", exercises: []))
        let entry = SetEntry(exercise: "Bench", reps: 8)
        try store.log(entry, in: session)
        XCTAssertThrowsError(try store.correct(session, entryID: entry.id, reps: 10))
    }

    func testEffectiveRepsUsesLatestCorrection() throws {
        let store = SessionStore()
        let (session, entry) = try lockedSession(store, reps: 8)
        try store.correct(session, entryID: entry.id, reps: 10)
        try store.correct(session, entryID: entry.id, reps: 9)
        XCTAssertEqual(store.effectiveReps(session.entries[0], in: session), 9)
    }
}
