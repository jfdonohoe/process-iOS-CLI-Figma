import Foundation
import SwiftData

/// The two things a user does to a session, with the one rule that protects
/// history: a locked session is never written. Each call saves; a failed save
/// is rolled back, so memory matches the store, and thrown to the caller so
/// it can be shown, not dropped.
enum SessionEditing {
    enum Failure: Error, Equatable {
        case sessionIsLocked
        case setIsNotInASession
    }

    /// Marks the session finished. A session never started counts as started now.
    static func finish(_ session: Session, in context: ModelContext, now: Date = .now) throws {
        guard !session.isLocked else { throw Failure.sessionIsLocked }
        if session.startedAt == nil { session.startedAt = now }
        session.finishedAt = now
        try save(context)
    }

    /// Ticks or unticks one set, if its session is unlocked.
    static func toggle(_ set: LoggedSet, in context: ModelContext) throws {
        guard let session = set.entry?.session else { throw Failure.setIsNotInASession }
        guard !session.isLocked else { throw Failure.sessionIsLocked }
        set.done.toggle()
        try save(context)
    }

    private static func save(_ context: ModelContext) throws {
        do { try context.save() } catch {
            context.rollback()
            throw error
        }
    }
}
