import Foundation

public enum PlanImport {
    /// Parses `name,sets,reps` lines. Lines that don't parse, such as a header, are skipped.
    public static func parse(_ text: String) -> [PlannedExercise] {
        text.split(whereSeparator: \.isNewline).compactMap { line in
            let parts = line.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 3, let sets = Int(parts[1]), let reps = Int(parts[2]) else {
                return nil
            }
            return PlannedExercise(name: parts[0], sets: sets, reps: reps)
        }
    }
}
