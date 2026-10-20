import Foundation

struct MonthGroup: Identifiable {
    let id: Date
    let title: String
    let sessions: [Session]
}

struct ExerciseCount: Identifiable {
    let name: String
    let doneSets: Int
    var id: String { name }
}

enum HistoryStats {
    /// Sessions grouped by calendar month, newest month first, sessions in
    /// the order they were given.
    static func sessionsByMonth(_ sessions: [Session], calendar: Calendar = .current) -> [MonthGroup] {
        let style = Date.FormatStyle(locale: calendar.locale ?? .current, calendar: calendar, timeZone: calendar.timeZone)
            .month(.wide).year()
        return Dictionary(grouping: sessions) { session in
            calendar.dateInterval(of: .month, for: session.scheduledFor)?.start ?? .distantPast
        }
        .sorted { $0.key > $1.key }
        .map { month, sessions in MonthGroup(id: month, title: month.formatted(style), sessions: sessions) }
    }

    /// How many sets have been ticked off per exercise name, across all
    /// sessions, by name. Exercises with nothing done are left out.
    static func doneSetsPerExercise(_ sessions: [Session]) -> [ExerciseCount] {
        sessions.flatMap(\.entries)
            .reduce(into: [String: Int]()) { counts, entry in
                if entry.doneSetCount > 0 { counts[entry.name, default: 0] += entry.doneSetCount }
            }
            .sorted { $0.key < $1.key }
            .map { ExerciseCount(name: $0.key, doneSets: $0.value) }
    }

    /// The sessions in the current training week: the 7-day block, counted
    /// from `anchor` (the first session ever scheduled), that `now` falls in.
    static func thisWeek(_ sessions: [Session], anchor: Date?, now: Date = .now,
                         calendar: Calendar = .current) -> [Session] {
        guard let anchor else { return [] }
        let current = weekBlock(of: now, from: anchor, calendar: calendar)
        return sessions.filter { weekBlock(of: $0.scheduledFor, from: anchor, calendar: calendar) == current }
    }

    /// Which 7-day training block a date falls in, counted from `anchor`: 0 for
    /// the anchor's day and the six after it, 1 for the next seven, negative
    /// before the anchor. Days are counted on the calendar between the two
    /// midnights, not as 86 400-second spans: a day across a DST change is 23
    /// or 25 hours long, and seconds arithmetic puts the first hours of a new
    /// block into the old one. The floor is taken on a Double because integer
    /// division truncates toward zero and would put the day before the anchor
    /// into block 0.
    static func weekBlock(of date: Date, from anchor: Date, calendar: Calendar) -> Int {
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: anchor),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        return Int((Double(days) / 7).rounded(.down))
    }
}
