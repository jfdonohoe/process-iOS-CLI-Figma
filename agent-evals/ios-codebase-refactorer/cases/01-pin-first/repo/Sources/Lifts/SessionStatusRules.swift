import Foundation

/// Works out what to call a session from its dates and its sets.
///
/// - Never started and still in the future: scheduled.
/// - Never started and in the past: missed.
/// - Started, not finished, not abandoned: started.
/// - Abandoned: abandoned, whatever else is set.
/// - Finished with every set done: completed; with some done: partial;
///   with none done: abandoned.
public enum SessionStatusRules {
    public static func status(for session: Session, now: Date) -> SessionStatus {
        var result = SessionStatus.scheduled
        var decided = false

        if session.startedAt != nil {
            if session.abandonedAt != nil {
                result = .abandoned
                decided = true
            } else {
                if session.finishedAt != nil {
                    if session.doneSetCount == session.totalSetCount {
                        result = .completed
                    } else {
                        if session.doneSetCount > 0 {
                            result = .partial
                        } else {
                            result = .abandoned
                        }
                    }
                    decided = true
                } else {
                    result = .started
                    decided = true
                }
            }
        } else {
            if session.abandonedAt != nil {
                result = .abandoned
                decided = true
            }
        }

        if !decided {
            if session.scheduledFor < now {
                result = .missed
            } else {
                result = .scheduled
            }
        }

        return result
    }
}
