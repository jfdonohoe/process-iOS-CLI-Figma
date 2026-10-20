import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Folder.self, Entry.self] }

    @Model
    final class Folder {
        var name: String
        @Relationship(deleteRule: .nullify, inverse: \Entry.folder) var entries: [Entry] = []

        init(name: String) { self.name = name }
    }

    @Model
    final class Entry {
        var createdAt: Date
        var mood: Mood
        var folder: Folder?

        init(mood: Mood) {
            self.createdAt = .now
            self.mood = mood
        }
    }
}
