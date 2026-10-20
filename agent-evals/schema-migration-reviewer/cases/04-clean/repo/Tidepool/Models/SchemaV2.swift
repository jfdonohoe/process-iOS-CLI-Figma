import Foundation
import SwiftData

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Entry.self] }

    @Model
    final class Entry {
        var id: UUID
        var createdAt: Date
        var rating: Int
        var note: String = ""

        init(rating: Int, note: String = "") {
            self.id = UUID()
            self.createdAt = .now
            self.rating = rating
            self.note = note
        }
    }
}
