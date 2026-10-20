import Foundation
import SwiftData

enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] { [Folder.self, Entry.self] }

    @Model
    final class Folder {
        var name: String
        var colorHex: String = "#FFFFFF"
        var cnt: Int = 0
        @Relationship(deleteRule: .cascade, inverse: \Entry.collection) var entries: [Entry] = []

        init(name: String) { self.name = name }
    }

    @Model
    final class Entry {
        var createdAt: Date
        var mood: Mood
        var note: String = ""
        @Relationship(originalName: "folder") var collection: Folder?

        init(mood: Mood) {
            self.createdAt = .now
            self.mood = mood
        }
    }
}
