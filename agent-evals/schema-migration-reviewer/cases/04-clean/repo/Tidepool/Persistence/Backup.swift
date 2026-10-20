import Foundation

struct EntryDTO: Codable {
    var id: UUID
    var createdAt: Date
    var rating: Int
    var note: String
    var place: String?
    var isPinned: Bool?
}

enum Backup {
    static func export(_ entries: [Entry]) throws -> Data {
        try JSONEncoder().encode(entries.map {
            EntryDTO(id: $0.id, createdAt: $0.createdAt, rating: $0.rating, note: $0.note,
                         place: $0.place, isPinned: $0.isPinned)
        })
    }
}
