import Foundation
import SwiftData

enum ImportError: Error, Equatable {
    case emptyFile
    case badHeader
    case badRow(Int)
    case duplicateExercise(String)
    case nothingToImport
}

/// Imports a routine from the spreadsheet export: a header row, then one
/// exercise per line as `name,section,sets,reps,weight`. The whole file is
/// imported or nothing is.
struct PlanImporter {
    let context: ModelContext

    private static let expectedHeader = ["name", "section", "sets", "reps", "weight"]
    private static let maxSets = 20
    private static let maxReps = 500

    @discardableResult
    func importRoutine(named routineName: String, from text: String) throws -> Routine {
        // Split the file into header and body rows.
        let rawLines = text.split(omittingEmptySubsequences: true, whereSeparator: \.isNewline)
        guard let headerLine = rawLines.first else { throw ImportError.emptyFile }
        let header = headerLine
            .split(separator: ",", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        guard header == Self.expectedHeader else { throw ImportError.badHeader }

        var cellsByRow: [(lineNumber: Int, cells: [String])] = []
        for (offset, line) in rawLines.dropFirst().enumerated() {
            let lineNumber = offset + 2
            let cells = line
                .split(separator: ",", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard cells.count == Self.expectedHeader.count else { throw ImportError.badRow(lineNumber) }
            cellsByRow.append((lineNumber, cells))
        }

        // Check every row before anything is written.
        var seenNames = Set<String>()
        var rows: [(name: String, section: SectionType, sets: Int, reps: Int, weightKg: Double)] = []
        for (lineNumber, cells) in cellsByRow {
            let name = cells[0]
            guard !name.isEmpty else { throw ImportError.badRow(lineNumber) }
            let key = name.lowercased()
            guard !seenNames.contains(key) else { throw ImportError.duplicateExercise(name) }
            seenNames.insert(key)

            guard let section = SectionType(rawValue: cells[1].lowercased()) else {
                throw ImportError.badRow(lineNumber)
            }
            guard let sets = Int(cells[2]), (1...Self.maxSets).contains(sets) else {
                throw ImportError.badRow(lineNumber)
            }
            guard let reps = Int(cells[3]), (0...Self.maxReps).contains(reps) else {
                throw ImportError.badRow(lineNumber)
            }

            let weightKg: Double
            if cells[4].isEmpty {
                weightKg = 0
            } else {
                guard let parsed = Double(cells[4]), parsed >= 0 else { throw ImportError.badRow(lineNumber) }
                weightKg = parsed
            }
            // Cardio and stretching rows carry no load.
            if section != .strength, weightKg > 0 {
                throw ImportError.badRow(lineNumber)
            }

            rows.append((name, section, sets, reps, weightKg))
        }
        guard !rows.isEmpty else { throw ImportError.nothingToImport }

        // Write the routine in one go.
        let routine = Routine(name: routineName)
        for (order, row) in rows.enumerated() {
            let exercise = PlannedExercise(
                name: row.name,
                section: row.section,
                sets: row.sets,
                reps: row.reps,
                weightKg: row.weightKg,
                order: order
            )
            routine.exercises.append(exercise)
        }
        context.insert(routine)
        try context.save()
        return routine
    }
}
