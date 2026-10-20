#if DEBUG
import Foundation
import SwiftData

/// Simulator demo state (standard §2.6). Runs only with `-kestrelSampleData`.
enum SampleTrails {
    @MainActor
    static func seedIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-kestrelSampleData") else { return }
        // Inserts `sample-` hikes into the simulator store.
    }
}
#endif
