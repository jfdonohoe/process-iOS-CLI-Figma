import Foundation

enum StreakCalculator {
    static func streak(days: [Date], calendar: Calendar = .current) -> Int {
        let unique = Set(days.map { calendar.startOfDay(for: $0) })
        var count = 0
        var day = calendar.startOfDay(for: .now)
        while unique.contains(day) {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }
}
