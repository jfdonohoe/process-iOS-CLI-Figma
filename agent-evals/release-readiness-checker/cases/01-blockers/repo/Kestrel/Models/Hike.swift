import Foundation
import SwiftData

@Model
final class Hike {
    var id: UUID
    var name: String
    var startedAt: Date
    var distanceMeters: Double
    var gpxFileName: String?

    init(name: String, startedAt: Date, distanceMeters: Double) {
        self.id = UUID()
        self.name = name
        self.startedAt = startedAt
        self.distanceMeters = distanceMeters
    }
}
