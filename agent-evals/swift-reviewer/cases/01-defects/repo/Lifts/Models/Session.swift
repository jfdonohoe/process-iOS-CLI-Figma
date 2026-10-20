import Foundation
import SwiftData

// A logged training session. Once `lockedAt` is set the session is recorded
// history: its stored values are never overwritten. Fixes are appended as
// `SetCorrection` records and layered on top when displayed.
@Model
final class Session {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var lockedAt: Date?
    @Relationship(deleteRule: .cascade) var entries: [Entry]
    @Relationship(deleteRule: .cascade) var corrections: [SetCorrection]

    var isLocked: Bool { lockedAt != nil }

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = .now
        self.updatedAt = .now
        self.entries = []
        self.corrections = []
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
    var weight: Double   // always kilograms; converted only for display
    var done: Bool

    init(index: Int, reps: Int, weight: Double) {
        self.id = UUID()
        self.index = index
        self.reps = reps
        self.weight = weight
        self.done = false
    }
}

@Model
final class SetCorrection {
    var id: UUID
    var setID: UUID
    var field: String
    var newValue: String   // weights in kilograms, as LoggedSet.weight
    var createdAt: Date

    init(setID: UUID, field: String, newValue: String) {
        self.id = UUID()
        self.setID = setID
        self.field = field
        self.newValue = newValue
        self.createdAt = .now
    }
}
