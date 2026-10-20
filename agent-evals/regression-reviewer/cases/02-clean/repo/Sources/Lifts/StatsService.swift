import Foundation

/// Keeps the Stats screen's totals current as workouts finish.
public final class StatsService {
    public private(set) var completedCount = 0

    public init() {}

    public func attach(to store: SessionStore) {
        store.onSessionLocked = { [weak self] session in
            if session.status == .completed {
                self?.completedCount += 1
            }
        }
    }
}
