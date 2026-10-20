import Foundation
import SwiftData

/// Edits made from the History screen. Recorded sessions only ever get
/// corrections appended; their stored values stay as logged.
enum HistoryEditError: Error { case notRecordedSet }

struct HistoryEditing {
    let context: ModelContext

    /// Fix a value on a recorded workout: appended, never overwritten.
    func correct(_ field: String, of set: LoggedSet, in session: Session, to value: String) throws {
        guard session.isLocked,
              session.entries.contains(where: { $0.sets.contains { $0.id == set.id } })
        else { throw HistoryEditError.notRecordedSet }
        let correction = SetCorrection(setID: set.id, field: field, newValue: value)
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
