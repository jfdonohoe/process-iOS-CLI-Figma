import Foundation

/// The lines shown when a workout is finished: one per logged set.
public enum SessionSummary {
    public static func lines(for session: Session, store: SessionStore) -> [String] {
        session.entries.map { entry in
            var parts = [entry.exercise]
            if let reps = store.effectiveReps(entry, in: session) {
                parts.append("\(reps) reps")
            }
            if let kg = entry.weightKg {
                parts.append(formatWeight(kg))
            }
            parts.append(entry.done ? "done" : "skipped")
            return parts.joined(separator: " · ")
        }
    }

    static func formatWeight(_ kilograms: Double) -> String {
        String(format: "%.1f kg", kilograms)
    }
}
