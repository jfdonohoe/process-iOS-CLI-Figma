import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var createdAt: Date
    var isPaused: Bool = false
    var reminderTime: Date?
    @Relationship(deleteRule: .cascade) var completions: [Completion] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
    }
}

@Model
final class Completion {
    var day: Date
    var habit: Habit?

    init(day: Date) { self.day = day }
}
