import Foundation
import SwiftData

struct EntryDTO: Codable {
    var id: UUID
    var createdAt: Date
    var mood: Int
    var note: String
    var tags: [String]?
    var energy: Int
}

enum Backup {
    static func export(_ entries: [Entry]) throws -> Data {
        let dtos = entries.map {
            EntryDTO(id: $0.id, createdAt: $0.createdAt, mood: $0.mood, note: $0.note,
                     tags: $0.tags, energy: $0.energy)
        }
        return try JSONEncoder().encode(dtos)
    }
}
