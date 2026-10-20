import XCTest
import SwiftData
@testable import Lifts

@MainActor
final class PlanImporterTests: XCTestCase {
    private var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema.lifts, configurations: config)
        context = ModelContext(container)
    }

    private let header = "name,section,sets,reps,weight\n"

    func testImportsRowsInFileOrder() throws {
        let routine = try PlanImporter(context: context).importRoutine(
            named: "Push",
            from: header + "Bench press,strength,3,8,60\nDips,strength,3,10,\nRow,cardio,1,1,0\n"
        )
        let exercises = routine.exercises.sorted { $0.order < $1.order }
        XCTAssertEqual(exercises.map(\.name), ["Bench press", "Dips", "Row"])
        XCTAssertEqual(exercises.map(\.weightKg), [60, 0, 0])
        XCTAssertEqual(exercises.map(\.section), [.strength, .strength, .cardio])
    }

    func testBlankWeightMeansZero() throws {
        let routine = try PlanImporter(context: context).importRoutine(named: "Pull", from: header + "Chin-up,strength,3,6,\n")
        XCTAssertEqual(routine.exercises.first?.weightKg, 0)
    }

    func testRejectsWrongHeader() {
        XCTAssertThrowsError(try PlanImporter(context: context).importRoutine(named: "X", from: "exercise,sets,reps\nBench,3,8\n")) {
            XCTAssertEqual($0 as? ImportError, .badHeader)
        }
    }

    func testRejectsDuplicateExerciseCaseInsensitively() {
        XCTAssertThrowsError(try PlanImporter(context: context).importRoutine(
            named: "X", from: header + "Bench press,strength,3,8,60\nbench press,strength,3,8,60\n"
        )) {
            XCTAssertEqual($0 as? ImportError, .duplicateExercise("bench press"))
        }
    }

    func testRejectsLoadOnCardioRowWithLineNumber() {
        XCTAssertThrowsError(try PlanImporter(context: context).importRoutine(
            named: "X", from: header + "Bench press,strength,3,8,60\nRow,cardio,1,1,20\n"
        )) {
            XCTAssertEqual($0 as? ImportError, .badRow(3))
        }
    }

    func testRejectsOutOfRangeSets() {
        XCTAssertThrowsError(try PlanImporter(context: context).importRoutine(named: "X", from: header + "Bench press,strength,21,8,60\n")) {
            XCTAssertEqual($0 as? ImportError, .badRow(2))
        }
    }

    func testBadRowWritesNothing() throws {
        XCTAssertThrowsError(try PlanImporter(context: context).importRoutine(
            named: "X", from: header + "Bench press,strength,3,8,60\nSquat,strength,0,5,80\n"
        ))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Routine>()), 0)
    }

    func testHeaderOnlyIsNothingToImport() {
        XCTAssertThrowsError(try PlanImporter(context: context).importRoutine(named: "X", from: header)) {
            XCTAssertEqual($0 as? ImportError, .nothingToImport)
        }
    }
}
