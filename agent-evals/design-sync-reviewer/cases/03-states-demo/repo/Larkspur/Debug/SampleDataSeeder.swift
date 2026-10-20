#if DEBUG && targetEnvironment(simulator)
import Foundation
import SwiftData

/// Simulator demo state (launch with -larkspurSampleData, or -larkspurSampleFlow=<phase>).
enum SampleDataSeeder {
    static func seedIfRequested(into context: ModelContext) {
        guard ProcessInfo.processInfo.arguments.contains("-larkspurSampleData") else { return }
        let existing = (try? context.fetch(FetchDescriptor<Plant>())) ?? []
        guard existing.isEmpty else { return }
        context.insert(Plant(name: "Monstera", location: "sample", waterEveryDays: 7, lastWatered: .now))
        context.insert(Plant(name: "Pothos", location: "sample", waterEveryDays: 5, lastWatered: .now))
        context.insert(Plant(name: "Snake Plant", location: "sample", waterEveryDays: 14, lastWatered: .now))
    }

    /// -larkspurSampleFlow=countdown|done renders WateringView in that phase.
    static var requestedFlow: WateringView.Phase? {
        let prefix = "-larkspurSampleFlow="
        guard let arg = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix(prefix) }) else { return nil }
        return WateringView.Phase(rawValue: String(arg.dropFirst(prefix.count)))
    }
}
#endif
