import Foundation
import SwiftData

typealias Folder = SchemaV2.Folder
typealias Entry = SchemaV2.Entry

enum Store {
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(schema: schema)
        return try ModelContainer(for: schema, migrationPlan: JournalMigrationPlan.self, configurations: config)
    }
}
