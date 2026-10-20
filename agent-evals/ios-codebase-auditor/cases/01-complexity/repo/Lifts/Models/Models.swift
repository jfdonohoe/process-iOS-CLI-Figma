import Foundation
import SwiftData

enum SectionType: String, Codable, CaseIterable {
    case strength, cardio, stretching
}

@Model
final class Routine {
    var id: UUID
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var exercises: [PlannedExercise]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
        self.exercises = []
    }
}

@Model
final class PlannedExercise {
    var id: UUID
    var name: String
    var section: SectionType
    var sets: Int
    var reps: Int
    var weightKg: Double
    var order: Int

    init(name: String, section: SectionType, sets: Int, reps: Int, weightKg: Double, order: Int) {
        self.id = UUID()
        self.name = name
        self.section = section
        self.sets = sets
        self.reps = reps
        self.weightKg = weightKg
        self.order = order
    }
}

/// One workout. `scheduledFor` is set when it is planned; the other dates are
/// set as the user moves through it. A session with `finishedAt` or
/// `abandonedAt` set is history and is never rewritten.
@Model
final class Session {
    var id: UUID
    var title: String
    var scheduledFor: Date
    var startedAt: Date?
    var finishedAt: Date?
    var abandonedAt: Date?
    @Relationship(deleteRule: .cascade) var entries: [Entry]

    var isLocked: Bool { finishedAt != nil || abandonedAt != nil }
    var totalSetCount: Int { entries.reduce(0) { $0 + $1.sets.count } }
    var doneSetCount: Int { entries.reduce(0) { $0 + $1.sets.filter(\.done).count } }

    init(title: String, scheduledFor: Date) {
        self.id = UUID()
        self.title = title
        self.scheduledFor = scheduledFor
        self.entries = []
    }
}

@Model
final class Entry {
    var id: UUID
    var name: String
    var order: Int
    @Relationship(deleteRule: .cascade) var sets: [LoggedSet]

    init(name: String, order: Int) {
        self.id = UUID()
        self.name = name
        self.order = order
        self.sets = []
    }
}

@Model
final class LoggedSet {
    var id: UUID
    var index: Int
    var reps: Int
    var weightKg: Double
    var done: Bool

    init(index: Int, reps: Int, weightKg: Double) {
        self.id = UUID()
        self.index = index
        self.reps = reps
        self.weightKg = weightKg
        self.done = false
    }
}

extension Schema {
    static let lifts = Schema([Routine.self, PlannedExercise.self, Session.self, Entry.self, LoggedSet.self])
}
