import Foundation
import SwiftData

/// Thirty days of sample sessions for screenshots.
enum SampleSessions {
    static func insert(into context: ModelContext) {
        for day in 0..<30 {
            let start = Calendar.current.date(byAdding: .day, value: -day, to: .now)!
            context.insert(BreathSession(startedAt: start, minutes: 5 + day % 10))
        }
        try? context.save()
    }
}
