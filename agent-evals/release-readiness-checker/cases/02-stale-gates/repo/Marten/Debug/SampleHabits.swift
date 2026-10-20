#if DEBUG
import Foundation

/// Simulator demo state. Runs only with `-martenSampleData`.
enum SampleHabits {
    @MainActor
    static func seedIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-martenSampleData") else { return }
        // Inserts `sample-` habits and four weeks of completions.
    }
}
#endif
