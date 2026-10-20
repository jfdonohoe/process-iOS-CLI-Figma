import Foundation

/// Finished sessions as CSV, one row per logged set.
public enum HistoryExport {
    public static let header = "session,exercise,reps,weight,done"

    public static func csv(_ sessions: [Session], store: SessionStore) -> String {
        var rows = [header]
        for session in sessions where session.finishedAt != nil {
            for entry in session.entries {
                let reps = store.effectiveReps(entry, in: session).map(String.init) ?? ""
                let weight = entry.weightKg.map(weightLabel) ?? ""
                rows.append("\(session.id.uuidString),\(entry.exercise),\(reps),\(weight),\(entry.done)")
            }
        }
        return rows.joined(separator: "\n")
    }

    static func weightLabel(_ kilograms: Double) -> String {
        String(format: "%.1f", kilograms) + " kg"
    }
}
