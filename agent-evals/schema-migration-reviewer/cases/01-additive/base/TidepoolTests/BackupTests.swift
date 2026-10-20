import Foundation
import SwiftData
import Testing
@testable import Tidepool

@MainActor
struct BackupTests {
    @Test func exportRoundTripsInMemory() throws {
        let container = try ModelContainer(for: Entry.self, configurations: .init(isStoredInMemoryOnly: true))
        let entry = Entry(mood: 4, note: "calm")
        container.mainContext.insert(entry)
        let data = try Backup.export([entry])
        let dtos = try JSONDecoder().decode([EntryDTO].self, from: data)
        #expect(dtos.first?.mood == 4)
    }
}
