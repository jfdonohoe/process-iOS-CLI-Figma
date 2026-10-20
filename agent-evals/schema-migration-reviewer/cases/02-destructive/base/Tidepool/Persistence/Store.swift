import Foundation
import SwiftData

enum Store {
    static var storeURL: URL {
        URL.applicationSupportDirectory.appending(path: "Tidepool.store")
    }

    static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(url: storeURL)
        return try ModelContainer(for: PracticeSession.self, DerivedMetric.self, configurations: config)
    }
}
