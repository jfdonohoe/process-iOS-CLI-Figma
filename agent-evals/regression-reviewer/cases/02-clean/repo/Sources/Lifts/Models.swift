import Foundation

public enum SessionStatus: String {
    case started
    case completed
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
    public let isDemo: Bool
    public var deletedAt: Date?

    init(lineageID: UUID, name: String, version: Int, exercises: [PlannedExercise], isDemo: Bool) {
        self.lineageID = lineageID
        self.name = name
        self.version = version
        self.exercises = exercises
        self.isDemo = isDemo
    }
}

public struct SetEntry {
    public let id = UUID()
    public let exercise: String
    public var reps: Int?
    public var weightKg: Double?
    public var distanceKm: Double?

    public init(exercise: String, reps: Int? = nil, weightKg: Double? = nil, distanceKm: Double? = nil) {
        self.exercise = exercise
        self.reps = reps
        self.weightKg = weightKg
        self.distanceKm = distanceKm
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
    public let isDemo: Bool
    public internal(set) var entries: [SetEntry] = []
    public internal(set) var corrections: [Correction] = []
    public internal(set) var status: SessionStatus = .started
    public internal(set) var lockedAt: Date?

    init(routineID: UUID, routineVersion: Int, snapshot: [PlannedExercise], isDemo: Bool) {
        self.routineID = routineID
        self.routineVersion = routineVersion
        self.snapshot = snapshot
        self.isDemo = isDemo
    }
}
