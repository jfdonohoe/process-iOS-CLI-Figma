import XCTest
@testable import Lifts

final class HistoryTests: XCTestCase {
    private let bench = PlannedExercise(name: "Bench", sets: 3, reps: 8)
    private let squat = PlannedExercise(name: "Squat", sets: 3, reps: 5)

    func testSessionKeepsSnapshotWhenRoutineEdited() {
        let store = SessionStore()
        let routine = store.addRoutine(name: "Push", exercises: [bench])
        let session = store.start(routine)
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
        let session = store.start(store.addRoutine(name: "Push", exercises: [bench]))
        try store.log(SetEntry(exercise: "Bench", reps: 8), in: session)
        store.finish(session)
        XCTAssertThrowsError(try store.log(SetEntry(exercise: "Bench", reps: 8), in: session)) { error in
            XCTAssertEqual(error as? StoreError, .locked)
        }
        XCTAssertEqual(session.entries.count, 1)
    }

    func testDistanceOnlyFinishesCompleted() throws {
        let store = SessionStore()
        let session = store.start(store.addRoutine(name: "Run", exercises: []))
        try store.log(SetEntry(exercise: "Run", distanceKm: 5), in: session)
        store.finish(session)
        XCTAssertEqual(session.status, .completed)
    }

    func testEmptySessionFinishesStarted() {
        let store = SessionStore()
        let session = store.start(store.addRoutine(name: "Push", exercises: [bench]))
        store.finish(session)
        XCTAssertEqual(session.status, .started)
        XCTAssertNotNil(session.lockedAt)
    }

    func testWeightOnlyFinishesCompleted() throws {
        let store = SessionStore()
        let session = store.start(store.addRoutine(name: "Carry", exercises: []))
        try store.log(SetEntry(exercise: "Carry", weightKg: 40), in: session)
        store.finish(session)
        XCTAssertEqual(session.status, .completed)
    }

    func testFinishingAgainLeavesLockedSessionAlone() throws {
        let store = SessionStore()
        let session = store.start(store.addRoutine(name: "Push", exercises: []))
        try store.log(SetEntry(exercise: "Bench", reps: 8), in: session)
        let first = Date(timeIntervalSince1970: 1_000)
        store.finish(session, at: first)
        store.finish(session, at: Date(timeIntervalSince1970: 2_000))
        XCTAssertEqual(session.lockedAt, first)
        XCTAssertEqual(session.status, .completed)
    }
}
