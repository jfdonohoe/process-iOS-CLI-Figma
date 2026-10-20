import Foundation
import SwiftData

@Model
final class Plant {
    var name: String
    var location: String
    var waterEveryDays: Int
    var lastWatered: Date?
    var notes: String = ""

    init(name: String, location: String, waterEveryDays: Int, lastWatered: Date? = nil) {
        self.name = name
        self.location = location
        self.waterEveryDays = waterEveryDays
        self.lastWatered = lastWatered
    }

    var isOverdue: Bool {
        guard let lastWatered else { return true }
        return Date().timeIntervalSince(lastWatered) > Double(waterEveryDays) * 86_400
    }
}
