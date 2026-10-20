import Foundation
import SwiftData

enum StoreError: Error { case locked }

struct SessionStore {
    let context: ModelContext

    /// Live edit during a session. Refuses recorded history.
    func setWeight(_ weight: Double, on set: LoggedSet, in session: Session) throws {
        guard !session.isLocked else { throw StoreError.locked }
        set.weight = weight
        session.updatedAt = .now
        try context.save()
    }

    func finish(_ session: Session) throws {
        session.lockedAt = .now
        session.updatedAt = .now
        try context.save()
    }
}
