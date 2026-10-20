#if DEBUG && targetEnvironment(simulator)
import Foundation
import SwiftData

/// Simulator demo state (standard §2.6). Runs only with `-wrenSampleData`.
enum SampleEntries {
    @MainActor
    static func seedIfRequested(_ context: ModelContext) {
        guard ProcessInfo.processInfo.arguments.contains("-wrenSampleData") else { return }
        // Inserts `sample-` entries with transcripts.
    }
}
#endif
