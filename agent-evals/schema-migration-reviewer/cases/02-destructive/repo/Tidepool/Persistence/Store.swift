import Foundation
import SwiftData

enum Store {
    static var storeURL: URL {
        URL.documentsDirectory.appending(path: "Sessions/Tidepool.store")
    }

    static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(url: storeURL)
        return try ModelContainer(for: PracticeSession.self, DerivedMetric.self, configurations: config)
    }
}
