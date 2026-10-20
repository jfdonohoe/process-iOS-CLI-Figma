import Foundation
import SwiftData

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
    @Relationship(deleteRule: .cascade, inverse: \Entry.session) var entries: [Entry]

    var isLocked: Bool { finishedAt != nil || abandonedAt != nil }
    /// Entries in workout order. SwiftData relationship arrays are unordered.
    var orderedEntries: [Entry] { entries.sorted { $0.order < $1.order } }
    var totalSetCount: Int { entries.reduce(0) { $0 + $1.sets.count } }
    var doneSetCount: Int { entries.reduce(0) { $0 + $1.doneSetCount } }

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
    var session: Session?
    @Relationship(deleteRule: .cascade, inverse: \LoggedSet.entry) var sets: [LoggedSet]

    /// Sets in set order. SwiftData relationship arrays are unordered.
    var orderedSets: [LoggedSet] { sets.sorted { $0.index < $1.index } }
    var doneSetCount: Int { sets.filter(\.done).count }

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
    var entry: Entry?

    init(index: Int, reps: Int, weightKg: Double) {
        self.id = UUID()
        self.index = index
        self.reps = reps
        self.weightKg = weightKg
        self.done = false
    }
}

/// The store's schema, versioned from the start so a later model change is a
/// migration stage, never a silent rebuild.
enum LiftsSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Session.self, Entry.self, LoggedSet.self] }
}

enum LiftsMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [LiftsSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

extension Schema {
    static let lifts = Schema(versionedSchema: LiftsSchemaV1.self)
}
