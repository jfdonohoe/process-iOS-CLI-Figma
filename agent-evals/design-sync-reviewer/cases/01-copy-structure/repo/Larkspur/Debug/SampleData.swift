#if DEBUG
import SwiftData
import Foundation

enum SampleData {
    static func seed(into context: ModelContext) {
        context.insert(Plant(name: "Monstera", location: "Living room", waterEveryDays: 7, lastWatered: .now))
        context.insert(Plant(name: "Fiddle Leaf Fig", location: "Bedroom", waterEveryDays: 10, lastWatered: .now))
    }
}
#endif
