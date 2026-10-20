import Foundation
import SwiftData

typealias Entry = SchemaV2.Entry

enum Store {
    static let currentSchema: any VersionedSchema.Type = SchemaV2.self

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV2.self)
        return try ModelContainer(for: schema, migrationPlan: TidepoolMigrationPlan.self,
                                  configurations: ModelConfiguration(schema: schema))
    }
}
