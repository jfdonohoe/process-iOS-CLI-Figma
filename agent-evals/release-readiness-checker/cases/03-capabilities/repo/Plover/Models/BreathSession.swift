import Foundation
import SwiftData

@Model
final class BreathSession {
    var id: UUID
    var startedAt: Date
    var minutes: Int
    var averageBPM: Double?

    init(startedAt: Date, minutes: Int) {
        self.id = UUID()
        self.startedAt = startedAt
        self.minutes = minutes
    }
}
