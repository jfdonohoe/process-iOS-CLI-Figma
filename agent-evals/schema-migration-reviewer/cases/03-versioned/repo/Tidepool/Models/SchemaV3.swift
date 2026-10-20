import Foundation
import SwiftData

enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Entry.self] }

    @Model
    final class Entry {
        var id: UUID
        var createdAt: Date
        var rating: Double
        var note: String = ""
        var place: String?

        init(rating: Double, note: String = "", place: String? = nil) {
            self.id = UUID()
            self.createdAt = .now
            self.rating = rating
            self.note = note
            self.place = place
        }
    }
}
