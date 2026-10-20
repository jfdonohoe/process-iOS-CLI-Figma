import XCTest
@testable import Lifts

final class DemoTests: XCTestCase {
    func pendingDeleteDemoKeepsUserSessions() {
        let store = SessionStore()
        let mine = store.start(store.addRoutine(name: "Mine", exercises: []))
        let demo = store.start(store.addRoutine(name: "Demo", exercises: [], isDemo: true), isDemo: true)
        let mineOnDemo = store.start(store.addRoutine(name: "Demo 2", exercises: [], isDemo: true))
        XCTAssertTrue(demo.isDemo)
        store.deleteDemoData()
        XCTAssertEqual(store.sessions.map(\.id), [mine.id, mineOnDemo.id])
    }

    func testDeleteDemoRemovesDemoRoutines() {
        let store = SessionStore()
        store.addRoutine(name: "Mine", exercises: [])
        store.addRoutine(name: "Demo", exercises: [], isDemo: true)
        store.deleteDemoData()
        XCTAssertEqual(store.routines.map(\.name), ["Mine"])
    }
}
