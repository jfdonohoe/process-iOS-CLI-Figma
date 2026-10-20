import Foundation

/// Reads a plan exported from a spreadsheet: one exercise per line,
/// "name,sets,reps,weight", after a header row.
/// The export comes from our own sheet template: no quoted fields, no spaces. Lines may end in "\n" or "\r\n", so splitting walks
/// unicode scalars (a Character would treat "\r\n" as one grapheme).
enum PlanCSV {
    struct Row { var name: String; var sets: Int; var reps: Int; var weight: Double }

    static func rows(from text: String) -> [Row] {
        var lines: [String] = []
        var current = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            if scalar == "\n" || scalar == "\r" {
                if !current.isEmpty { lines.append(String(current)) }
                current = String.UnicodeScalarView()
            } else {
                current.append(scalar)
            }
        }
        if !current.isEmpty { lines.append(String(current)) }

        return lines.dropFirst().compactMap { line in
            let f = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            guard f.count == 4, let s = Int(f[1]), let r = Int(f[2]), let w = Double(f[3]) else { return nil }
            return Row(name: f[0], sets: s, reps: r, weight: w)
        }
    }

    /// Two-letter badge for an exercise name, e.g. "Bench Press" -> "BP".
    /// Characters are right here: a badge must not split an emoji or accent.
    static func initials(of name: String) -> String {
        var out = ""
        var atWordStart = true
        for ch in name.uppercased() {
            if ch == " " { atWordStart = true; continue }
            if atWordStart { out.append(ch); atWordStart = false }
            if out.count == 2 { break }
        }
        return out
    }
}
