import Foundation
import SwiftData

struct EntryDTO: Codable {
    var id: UUID
    var createdAt: Date
    var mood: Int
    var note: String
}

enum Backup {
    static func export(_ entries: [Entry]) throws -> Data {
        let dtos = entries.map {
            EntryDTO(id: $0.id, createdAt: $0.createdAt, mood: $0.mood, note: $0.note)
        }
        return try JSONEncoder().encode(dtos)
    }
}
