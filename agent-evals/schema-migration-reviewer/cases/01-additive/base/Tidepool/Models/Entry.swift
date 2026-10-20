import Foundation
import SwiftData

@Model
final class Entry {
    var id: UUID
    var createdAt: Date
    var mood: Int
    var note: String

    init(mood: Int, note: String) {
        self.id = UUID()
        self.createdAt = .now
        self.mood = mood
        self.note = note
    }
}
