import Foundation
import SwiftData

enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] { [Entry.self] }

    @Model
    final class Entry {
        var id: UUID
        var createdAt: Date
        var rating: Int
        var note: String = ""
        var place: String?
        var isPinned: Bool = false

        init(rating: Int, note: String = "", place: String? = nil, isPinned: Bool = false) {
            self.id = UUID()
            self.createdAt = .now
            self.rating = rating
            self.note = note
            self.place = place
            self.isPinned = isPinned
        }
    }
}
