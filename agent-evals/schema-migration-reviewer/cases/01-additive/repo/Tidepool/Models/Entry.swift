import Foundation
import SwiftData

@Model
final class Entry {
    var id: UUID
    var createdAt: Date
    var mood: Int
    var note: String
    var durationSeconds: Int
    var tags: [String]?
    var energy: Int = 3
    @Transient var draftText: String = ""

    var isGoodDay: Bool { mood >= 4 }

    init(mood: Int, note: String, durationSeconds: Int, energy: Int = 3) {
        self.id = UUID()
        self.createdAt = .now
        self.mood = mood
        self.note = note
        self.durationSeconds = durationSeconds
        self.energy = energy
    }
}
