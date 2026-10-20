import Foundation
import SwiftData

enum WrenSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Entry.self] }

    @Model
    final class Entry {
        var id: UUID
        var recordedAt: Date
        var audioFileName: String

        init(recordedAt: Date, audioFileName: String) {
            self.id = UUID()
            self.recordedAt = recordedAt
            self.audioFileName = audioFileName
        }
    }
}

enum WrenSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Entry.self] }

    @Model
    final class Entry {
        var id: UUID
        var recordedAt: Date
        var audioFileName: String
        var transcript: String?

        init(recordedAt: Date, audioFileName: String) {
            self.id = UUID()
            self.recordedAt = recordedAt
            self.audioFileName = audioFileName
        }
    }
}

enum WrenMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [WrenSchemaV1.self, WrenSchemaV2.self] }
    static var stages: [MigrationStage] { [.lightweight(fromVersion: WrenSchemaV1.self, toVersion: WrenSchemaV2.self)] }
}

typealias Entry = WrenSchemaV2.Entry
