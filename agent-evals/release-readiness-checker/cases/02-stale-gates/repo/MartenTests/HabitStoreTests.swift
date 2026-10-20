import Testing
import SwiftData
@testable import Marten

@MainActor
struct HabitStoreTests {
    @Test func pauseKeepsCompletions() throws {
        let container = try ModelContainer(for: Habit.self, configurations: .init(isStoredInMemoryOnly: true))
        let habit = Habit(name: "Read")
        habit.completions.append(Completion(day: .now))
        container.mainContext.insert(habit)
        HabitStore(context: container.mainContext).pause(habit)
        #expect(habit.completions.count == 1)
    }
}
