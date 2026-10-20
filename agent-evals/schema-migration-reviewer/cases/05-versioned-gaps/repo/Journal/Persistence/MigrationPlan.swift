import Foundation
import SwiftData

enum JournalMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self, SchemaV3.self] }
    static var stages: [MigrationStage] { [v1ToV2, v2ToV3] }

    static let v1ToV2 = MigrationStage.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)

    static let v2ToV3 = MigrationStage.custom(
        fromVersion: SchemaV2.self, toVersion: SchemaV3.self,
        willMigrate: nil,
        didMigrate: { context in
            for folder in try context.fetch(FetchDescriptor<SchemaV3.Folder>()) {
                folder.cnt = folder.entries.count
            }
            try? context.save()
        }
    )
}
