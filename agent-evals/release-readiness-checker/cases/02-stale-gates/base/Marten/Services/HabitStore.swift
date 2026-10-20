import Foundation
import SwiftData

@MainActor
struct HabitStore {
    let context: ModelContext

    func pause(_ habit: Habit) {
        habit.isPaused = true
    }

    func remove(_ habit: Habit) {
        context.delete(habit)
    }
}
