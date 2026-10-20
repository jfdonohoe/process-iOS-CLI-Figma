import XCTest
@testable import Lifts

final class StatsTests: XCTestCase {
    func testStatsCountsCompletedSessions() throws {
        let store = SessionStore()
        let stats = StatsService()
        stats.attach(to: store)
        let session = store.start(store.addRoutine(name: "Push", exercises: []))
        try store.log(SetEntry(exercise: "Bench", reps: 8), in: session)
        store.finish(session)
        XCTAssertEqual(stats.completedCount, 1)
    }

    func testAppEnvironmentCountsFinishedWorkouts() throws {
        let env = AppEnvironment.make()
        let session = env.store.start(env.store.addRoutine(name: "Push", exercises: []))
        try env.store.log(SetEntry(exercise: "Bench", reps: 8), in: session)
        env.store.finish(session)
        XCTAssertEqual(env.stats.completedCount, 1)
    }
}
