import Foundation

/// Turns a stored weight into the text the user sees.
protocol WeightFormatting {
    func string(forKilograms kilograms: Double) -> String
}

/// Weights are stored in kilograms and shown in kilograms.
struct KilogramFormatter: WeightFormatting {
    func string(forKilograms kilograms: Double) -> String {
        kilograms.formatted(.number.precision(.fractionLength(0...1))) + " kg"
    }
}

/// Writes a finished session out for sharing.
protocol SessionExporter {
    var fileExtension: String { get }
    func export(_ session: Session, weights: WeightFormatting) -> String
}

struct CSVSessionExporter: SessionExporter {
    let fileExtension = "csv"

    func export(_ session: Session, weights: WeightFormatting) -> String {
        var lines = ["exercise,set,reps,weight,done"]
        for entry in session.entries.sorted(by: { $0.order < $1.order }) {
            for set in entry.sets.sorted(by: { $0.index < $1.index }) {
                lines.append("\(entry.name),\(set.index + 1),\(set.reps),\(weights.string(forKilograms: set.weightKg)),\(set.done)")
            }
        }
        return lines.joined(separator: "\n")
    }
}

struct MarkdownSessionExporter: SessionExporter {
    let fileExtension = "md"

    func export(_ session: Session, weights: WeightFormatting) -> String {
        var lines = ["# \(session.title)", ""]
        for entry in session.entries.sorted(by: { $0.order < $1.order }) {
            lines.append("## \(entry.name)")
            for set in entry.sets.sorted(by: { $0.index < $1.index }) {
                let mark = set.done ? "x" : " "
                lines.append("- [\(mark)] \(set.reps) × \(weights.string(forKilograms: set.weightKg))")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case csv = "CSV"
    case markdown = "Markdown"

    var id: String { rawValue }

    var exporter: SessionExporter {
        switch self {
        case .csv: CSVSessionExporter()
        case .markdown: MarkdownSessionExporter()
        }
    }
}

/// Labels from the 1.0 share sheet, which showed pounds alongside kilograms.
enum WeightLabels {
    static func pounds(_ kilograms: Double) -> String {
        let pounds = kilograms * 2.20462
        return pounds.formatted(.number.precision(.fractionLength(0))) + " lb"
    }
}
