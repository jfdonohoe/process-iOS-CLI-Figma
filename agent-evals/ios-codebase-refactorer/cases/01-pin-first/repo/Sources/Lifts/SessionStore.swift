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

    public init() {}

    @discardableResult
    public func addRoutine(name: String, exercises: [PlannedExercise]) -> Routine {
        let routine = Routine(lineageID: UUID(), name: name, version: 1, exercises: exercises)
        routines.append(routine)
        return routine
    }

    /// Editing adds a new version. The version past sessions point at is left alone.
    @discardableResult
    public func editRoutine(_ routine: Routine, exercises: [PlannedExercise]) -> Routine {
        let next = Routine(lineageID: routine.lineageID, name: routine.name, version: routine.version + 1, exercises: exercises)
        routines.append(next)
        return next
    }

    @discardableResult
    public func schedule(_ routine: Routine, for date: Date) -> Session {
        let session = Session(routineID: routine.id, routineVersion: routine.version, snapshot: routine.exercises, scheduledFor: date)
        sessions.append(session)
        return session
    }

    public func start(_ session: Session, at date: Date = Date()) throws {
        guard !session.isLocked else { throw StoreError.locked }
        if session.startedAt == nil { session.startedAt = date }
    }

    public func log(_ entry: SetEntry, in session: Session) throws {
        guard !session.isLocked else { throw StoreError.locked }
        session.entries.append(entry)
    }

    public func finish(_ session: Session, at date: Date = Date()) {
        guard !session.isLocked else { return }
        if session.startedAt == nil { session.startedAt = date }
        session.finishedAt = date
    }

    public func abandon(_ session: Session, at date: Date = Date()) {
        guard !session.isLocked else { return }
        session.abandonedAt = date
    }

    /// Corrections are appended. The logged value stays as it was.
    public func correct(_ session: Session, entryID: UUID, reps: Int?, at date: Date = Date()) throws {
        guard session.isLocked else { throw StoreError.notLocked }
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
}
