import Foundation
import SwiftData

typealias Entry = SchemaV3.Entry

enum Store {
    static let currentSchema: any VersionedSchema.Type = SchemaV3.self

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV3.self)
        return try ModelContainer(for: schema, migrationPlan: TidepoolMigrationPlan.self,
                                  configurations: ModelConfiguration(schema: schema))
    }
}
