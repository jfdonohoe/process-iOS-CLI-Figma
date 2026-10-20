import Foundation

enum SessionStatus: String {
    case scheduled, started, completed, partial, missed, abandoned
}

extension Session {
    /// What to call the session, from its dates and its sets.
    ///
    /// Abandoned wins over everything. A finished session is completed,
    /// partial or abandoned by how many sets were ticked. Otherwise it is
    /// started if it was started, missed if its date has passed, and
    /// scheduled if not.
    func status(at now: Date) -> SessionStatus {
        guard abandonedAt == nil else { return .abandoned }
        if finishedAt != nil {
            switch doneSetCount {
            case totalSetCount: return .completed
            case 0: return .abandoned
            default: return .partial
            }
        }
        guard startedAt == nil else { return .started }
        return scheduledFor < now ? .missed : .scheduled
    }
}
