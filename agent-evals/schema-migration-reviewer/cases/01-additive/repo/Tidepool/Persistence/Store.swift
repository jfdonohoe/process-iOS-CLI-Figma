import Foundation
import SwiftData

enum Store {
    static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration("Tidepool")
        return try ModelContainer(for: Entry.self, Reminder.self, configurations: config)
    }
}
