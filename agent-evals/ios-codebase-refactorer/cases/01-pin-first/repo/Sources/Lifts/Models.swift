import Foundation

public enum SessionStatus: String {
    case scheduled, started, completed, partial, missed, abandoned
}

public struct PlannedExercise: Equatable {
    public var name: String
    public var sets: Int
    public var reps: Int

    public init(name: String, sets: Int, reps: Int) {
        self.name = name
        self.sets = sets
        self.reps = reps
    }
}

public final class Routine {
    public let id = UUID()
    /// Shared by every version of the same routine.
    public let lineageID: UUID
    public var name: String
    public let version: Int
    public let exercises: [PlannedExercise]

    init(lineageID: UUID, name: String, version: Int, exercises: [PlannedExercise]) {
        self.lineageID = lineageID
        self.name = name
        self.version = version
        self.exercises = exercises
    }
}

public struct SetEntry {
    public let id = UUID()
    public let exercise: String
    public var reps: Int?
    public var weightKg: Double?
    public var done: Bool

    public init(exercise: String, reps: Int? = nil, weightKg: Double? = nil, done: Bool = false) {
        self.exercise = exercise
        self.reps = reps
        self.weightKg = weightKg
        self.done = done
    }
}

public struct Correction {
    public let entryID: UUID
    public let oldReps: Int?
    public let newReps: Int?
    public let at: Date
}

public final class Session {
    public let id = UUID()
    public let routineID: UUID
    public let routineVersion: Int
    /// What was planned when the session started. Never re-read from the routine.
    public let snapshot: [PlannedExercise]
    public let scheduledFor: Date
    public internal(set) var startedAt: Date?
    public internal(set) var finishedAt: Date?
    public internal(set) var abandonedAt: Date?
    public internal(set) var entries: [SetEntry] = []
    public internal(set) var corrections: [Correction] = []

    public var isLocked: Bool { finishedAt != nil || abandonedAt != nil }
    public var totalSetCount: Int { entries.count }
    public var doneSetCount: Int { entries.filter(\.done).count }

    init(routineID: UUID, routineVersion: Int, snapshot: [PlannedExercise], scheduledFor: Date) {
        self.routineID = routineID
        self.routineVersion = routineVersion
        self.snapshot = snapshot
        self.scheduledFor = scheduledFor
    }
}
