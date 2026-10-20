import Foundation

struct MonthGroup: Identifiable {
    let id: DateComponents
    let title: String
    let sessions: [Session]
}

enum HistoryStats {
    /// Sessions grouped by calendar month, newest month first, sessions in
    /// the order they were given.
    static func sessionsByMonth(_ sessions: [Session], calendar: Calendar = .current) -> [MonthGroup] {
        var groups: [DateComponents: [Session]] = [:]
        var order: [DateComponents] = []
        for session in sessions {
            let month = calendar.dateComponents([.year, .month], from: session.scheduledFor)
            if groups[month] == nil {
                groups[month] = []
                order.append(month)
            }
            groups[month]?.append(session)
        }

        var result: [MonthGroup] = []
        for month in order {
            let style = Date.FormatStyle(calendar: calendar, timeZone: calendar.timeZone).month(.wide).year()
            let title = calendar.date(from: month).map { $0.formatted(style) } ?? "Unknown"
            result.append(MonthGroup(id: month, title: title, sessions: groups[month] ?? []))
        }
        result.sort { lhs, rhs in
            let l = calendar.date(from: lhs.id) ?? .distantPast
            let r = calendar.date(from: rhs.id) ?? .distantPast
            return l > r
        }
        return result
    }

    /// How many sets have been ticked off per exercise name, across all sessions.
    static func doneSetsPerExercise(_ sessions: [Session]) -> [String: Int] {
        var counts: [String: Int] = [:]
        for session in sessions {
            for entry in session.entries {
                for set in entry.sets where set.done {
                    if let existing = counts[entry.name] {
                        counts[entry.name] = existing + 1
                    } else {
                        counts[entry.name] = 1
                    }
                }
            }
        }
        return counts
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
