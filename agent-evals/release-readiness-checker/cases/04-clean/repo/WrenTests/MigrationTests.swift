import Foundation
import SwiftData
import Testing
@testable import Wren

@MainActor
struct MigrationTests {
    /// `Fixtures/Wren-2.0.0.store` was written by the 2.0.0 App Store build.
    @Test func opensStoreFromPreviousRelease() throws {
        let fixture = try #require(Bundle(for: Marker.self).url(forResource: "Wren-2.0.0", withExtension: "store"))
        let copy = URL.temporaryDirectory.appending(path: UUID().uuidString + ".store")
        try FileManager.default.copyItem(at: fixture, to: copy)
        let schema = Schema(versionedSchema: WrenSchemaV2.self)
        let container = try ModelContainer(for: schema, migrationPlan: WrenMigrationPlan.self,
                                           configurations: ModelConfiguration(url: copy))
        let entries = try container.mainContext.fetch(FetchDescriptor<Entry>())
        #expect(entries.count == 12)
        #expect(entries.allSatisfy { $0.transcript == nil })
    }
}

private final class Marker {}
