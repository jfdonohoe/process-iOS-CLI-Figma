import XCTest
@testable import Lifts

final class HistoryStatsTests: XCTestCase {
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        c.locale = Locale(identifier: "en_GB")
        return c
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 9))!
    }

    private func session(_ title: String, on date: Date, done: Int = 0, of total: Int = 0) -> Session {
        makeSession(title: title, exercise: title, on: date, sets: (0..<total).map { $0 < done })
    }

    func testGroupsByMonthNewestFirstKeepingInputOrder() {
        let a = session("A", on: date(2026, 3, 2))
        let b = session("B", on: date(2026, 4, 10))
        let c = session("C", on: date(2026, 3, 20))
        let groups = HistoryStats.sessionsByMonth([a, c, b], calendar: calendar)
        XCTAssertEqual(groups.map(\.title), ["April 2026", "March 2026"])
        XCTAssertEqual(groups[1].sessions.map(\.title), ["A", "C"])
    }

    func testCountsDoneSetsPerExerciseAcrossSessions() {
        let counts = HistoryStats.doneSetsPerExercise([
            session("Bench", on: date(2026, 3, 2), done: 2, of: 3),
            session("Bench", on: date(2026, 3, 9), done: 3, of: 3),
            session("Squat", on: date(2026, 3, 9), done: 0, of: 3),
        ])
        XCTAssertEqual(counts.map(\.name), ["Bench"])
        XCTAssertEqual(counts.first?.doneSets, 5)
    }

    func testThisWeekIsTheAnchorsBlockContainingNow() {
        let anchor = date(2026, 3, 23)
        let inWeekTwo = session("B", on: date(2026, 3, 31))
        let sessions = [session("A", on: anchor), inWeekTwo, session("C", on: date(2026, 4, 7))]
        let thisWeek = HistoryStats.thisWeek(sessions, anchor: anchor, now: date(2026, 4, 2), calendar: calendar)
        XCTAssertEqual(thisWeek.map(\.title), ["B"])
    }

    func testThisWeekIsEmptyWithoutAnAnchor() {
        XCTAssertTrue(HistoryStats.thisWeek([session("A", on: date(2026, 3, 23))], anchor: nil, calendar: calendar).isEmpty)
    }

    func testWeekBlocksAreSevenCalendarDaysFromTheAnchor() {
        let anchor = date(2026, 3, 23)
        XCTAssertEqual(HistoryStats.weekBlock(of: date(2026, 3, 23), from: anchor, calendar: calendar), 0)
        XCTAssertEqual(HistoryStats.weekBlock(of: date(2026, 4, 5), from: anchor, calendar: calendar), 1)
        XCTAssertEqual(HistoryStats.weekBlock(of: date(2026, 4, 6), from: anchor, calendar: calendar), 2)
    }

    func testDayBeforeAnchorIsBlockMinusOne() {
        let anchor = date(2026, 3, 23)
        XCTAssertEqual(HistoryStats.weekBlock(of: date(2026, 3, 22), from: anchor, calendar: calendar), -1)
    }

    func testBlockBoundaryHoldsAcrossDSTChange() {
        // The UK clocks go forward on 2026-03-29, so Mon 23 Mar 00:00 to Mon 30 Mar 00:30
        // is 167.5 hours: less than seven 24-hour days, but seven calendar days.
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 3, day: 23))!
        let justIntoWeekTwo = calendar.date(from: DateComponents(year: 2026, month: 3, day: 30, hour: 0, minute: 30))!
        XCTAssertEqual(HistoryStats.weekBlock(of: justIntoWeekTwo, from: anchor, calendar: calendar), 1)
    }
}
