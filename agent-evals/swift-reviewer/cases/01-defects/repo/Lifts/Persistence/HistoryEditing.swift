import Foundation
import SwiftData

/// Edits made from the History screen.
struct HistoryEditing {
    let context: ModelContext

    /// Fix a weight typed wrong during a workout that is already recorded.
    func fixWeight(of set: LoggedSet, in session: Session, to weight: Double) throws {
        set.weight = weight
        session.updatedAt = .now
        try context.save()
    }

    /// Fix the rep count on a recorded workout: appended, never overwritten.
    func fixReps(of set: LoggedSet, in session: Session, to reps: Int) throws {
        let correction = SetCorrection(setID: set.id, field: "reps", newValue: String(reps))
        session.corrections.append(correction)
        session.updatedAt = .now
        try context.save()
    }

    /// Rename a workout that is still in progress.
    func rename(_ session: Session, to title: String) throws {
        guard !session.isLocked else { throw StoreError.locked }
        session.title = title
        session.updatedAt = .now
        try context.save()
    }
}
