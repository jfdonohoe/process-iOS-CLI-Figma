import Foundation
import SwiftData
import Testing
@testable import Tidepool

/// Opens the store fixture written by the last release, using the current
/// schema and migration plan, and reads every entry back.
@MainActor
struct MigrationTests {
    @Test func opensLastReleaseStore() throws {
        let fixture = URL(filePath: #filePath).deletingLastPathComponent().appending(path: "Fixtures/release-store.store")
        let copy = URL.temporaryDirectory.appending(path: UUID().uuidString + ".store")
        try FileManager.default.copyItem(at: fixture, to: copy)
        let schema = Schema(versionedSchema: Store.currentSchema)
        let container = try ModelContainer(for: schema, migrationPlan: TidepoolMigrationPlan.self,
                                           configurations: ModelConfiguration(schema: schema, url: copy))
        let entries = try container.mainContext.fetch(FetchDescriptor<Entry>())
        #expect(entries.count == 12)
    }
}
