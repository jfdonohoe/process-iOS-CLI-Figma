import XCTest
@testable import Lifts

final class HistoryTests: XCTestCase {
    private let bench = PlannedExercise(name: "Bench", sets: 3, reps: 8)
    private let squat = PlannedExercise(name: "Squat", sets: 3, reps: 5)
    private let day = Date(timeIntervalSince1970: 1_700_000_000)

    func testSessionKeepsSnapshotWhenRoutineEdited() {
        let store = SessionStore()
        let routine = store.addRoutine(name: "Push", exercises: [bench])
        let session = store.schedule(routine, for: day)
        store.editRoutine(routine, exercises: [bench, squat])
        XCTAssertEqual(session.snapshot, [bench])
        XCTAssertEqual(session.routineVersion, 1)
    }

    func testEditCreatesNewVersion() {
        let store = SessionStore()
        let routine = store.addRoutine(name: "Push", exercises: [bench])
        let next = store.editRoutine(routine, exercises: [squat])
        XCTAssertEqual(next.version, 2)
        XCTAssertEqual(next.lineageID, routine.lineageID)
        XCTAssertEqual(routine.exercises, [bench])
        XCTAssertEqual(store.routines.count, 2)
    }

    func testLockedSessionRejectsNewSets() throws {
        let store = SessionStore()
        let session = store.schedule(store.addRoutine(name: "Push", exercises: [bench]), for: day)
        try store.log(SetEntry(exercise: "Bench", reps: 8, done: true), in: session)
        store.finish(session, at: day)
        XCTAssertThrowsError(try store.log(SetEntry(exercise: "Bench", reps: 8), in: session)) { error in
            XCTAssertEqual(error as? StoreError, .locked)
        }
        XCTAssertEqual(session.entries.count, 1)
    }

    func testFinishingAgainLeavesLockedSessionAlone() throws {
        let store = SessionStore()
        let session = store.schedule(store.addRoutine(name: "Push", exercises: []), for: day)
        try store.log(SetEntry(exercise: "Bench", reps: 8, done: true), in: session)
        store.finish(session, at: day)
        store.finish(session, at: day.addingTimeInterval(1_000))
        XCTAssertEqual(session.finishedAt, day)
    }

    func testFinishingSetsStartedAtWhenNeverStarted() {
        let store = SessionStore()
        let session = store.schedule(store.addRoutine(name: "Push", exercises: []), for: day)
        store.finish(session, at: day)
        XCTAssertEqual(session.startedAt, day)
        XCTAssertTrue(session.isLocked)
    }

    func testAbandonedSessionCannotBeStarted() {
        let store = SessionStore()
        let session = store.schedule(store.addRoutine(name: "Push", exercises: []), for: day)
        store.abandon(session, at: day)
        XCTAssertThrowsError(try store.start(session, at: day)) { error in
            XCTAssertEqual(error as? StoreError, .locked)
        }
    }
}
