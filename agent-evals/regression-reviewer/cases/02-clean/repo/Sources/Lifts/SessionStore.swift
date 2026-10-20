import Foundation

public enum StoreError: Error, Equatable {
    case locked
    case notLocked
    case unknownEntry
}

/// All mutation of routines and sessions goes through here.
public final class SessionStore {
    public private(set) var routines: [Routine] = []
    public private(set) var sessions: [Session] = []

    /// Called once, when a session is finished and locked.
    public var onSessionLocked: ((Session) -> Void)?

    public init() {}

    @discardableResult
    public func addRoutine(name: String, exercises: [PlannedExercise], isDemo: Bool = false) -> Routine {
        let routine = Routine(lineageID: UUID(), name: name, version: 1, exercises: exercises, isDemo: isDemo)
        routines.append(routine)
        return routine
    }

    /// Editing adds a new version. The version past sessions point at is left alone.
    @discardableResult
    public func editRoutine(_ routine: Routine, exercises: [PlannedExercise]) -> Routine {
        let next = Routine(
            lineageID: routine.lineageID,
            name: routine.name,
            version: routine.version + 1,
            exercises: exercises,
            isDemo: routine.isDemo
        )
        routines.append(next)
        return next
    }

    /// Only the demo seeder passes `isDemo: true`. A workout the user runs is theirs,
    /// even on a demo routine, so deleting demo data never takes it.
    public func start(_ routine: Routine, isDemo: Bool = false) -> Session {
        let session = Session(
            routineID: routine.id,
            routineVersion: routine.version,
            snapshot: routine.exercises,
            isDemo: isDemo
        )
        sessions.append(session)
        return session
    }

    public func log(_ entry: SetEntry, in session: Session) throws {
        guard session.lockedAt == nil else { throw StoreError.locked }
        session.entries.append(entry)
    }

    public func finish(_ session: Session, at date: Date = Date()) {
        guard session.lockedAt == nil else { return }
        session.status = session.entries.contains(where: isDone) ? .completed : .started
        session.lockedAt = date
        onSessionLocked?(session)
    }

    /// A set counts as done when any value was logged, distance included.
    func isDone(_ entry: SetEntry) -> Bool {
        entry.reps != nil || entry.weightKg != nil || entry.distanceKm != nil
    }

    /// Corrections are appended. The logged value stays as it was.
    public func correct(_ session: Session, entryID: UUID, reps: Int?, at date: Date = Date()) throws {
        guard session.lockedAt != nil else { throw StoreError.notLocked }
        guard let entry = session.entries.first(where: { $0.id == entryID }) else {
            throw StoreError.unknownEntry
        }
        session.corrections.append(Correction(entryID: entryID, oldReps: entry.reps, newReps: reps, at: date))
    }

    /// The value to show: the latest correction if there is one, otherwise what was logged.
    public func effectiveReps(_ entry: SetEntry, in session: Session) -> Int? {
        if let latest = session.corrections.last(where: { $0.entryID == entry.id }) {
            return latest.newReps
        }
        return entry.reps
    }

    public func softDelete(_ routine: Routine, at date: Date = Date()) {
        routine.deletedAt = date
    }

    /// Removes demo routines and demo sessions. Demo history may go; the user's may not.
    public func deleteDemoData() {
        sessions.removeAll { $0.isDemo }
        routines.removeAll { $0.isDemo }
    }

    /// Whether the user has data of their own. Demo data is cleared once this is true.
    public var hasUserData: Bool {
        routines.contains { !$0.isDemo } || sessions.contains { !$0.isDemo }
    }
}
