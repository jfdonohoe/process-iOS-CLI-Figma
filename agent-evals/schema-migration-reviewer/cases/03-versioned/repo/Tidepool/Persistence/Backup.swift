import Foundation

struct EntryDTO: Codable {
    var id: UUID
    var createdAt: Date
    var rating: Double
    var note: String
    var place: String?
}

enum Backup {
    static func export(_ entries: [SchemaV3.Entry]) throws -> Data {
        try JSONEncoder().encode(entries.map {
            EntryDTO(id: $0.id, createdAt: $0.createdAt, rating: $0.rating, note: $0.note, place: $0.place)
        })
    }
}
