import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Entry.self] }

    @Model
    final class Entry {
        var id: UUID
        var createdAt: Date
        var rating: Int

        init(rating: Int) {
            self.id = UUID()
            self.createdAt = .now
            self.rating = rating
        }
    }
}
