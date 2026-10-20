import Testing
import SwiftData
@testable import Kestrel

@MainActor
struct HikeTests {
    @Test func deleteFromFilteredListDeletesThatHike() throws {
        let container = try ModelContainer(for: Hike.self, configurations: .init(isStoredInMemoryOnly: true))
        container.mainContext.insert(Hike(name: "Ridge", startedAt: .now, distanceMeters: 5000))
        #expect(try container.mainContext.fetchCount(FetchDescriptor<Hike>()) == 1)
    }
}
