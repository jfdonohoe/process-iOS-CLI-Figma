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

typealias Entry = WrenSchemaV1.Entry
