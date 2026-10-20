import Foundation
import SwiftData

@MainActor
struct HabitStore {
    let context: ModelContext

    func pause(_ habit: Habit) {
        habit.isPaused = true
    }

    /// Archived habits keep their history and drop out of the Today list.
    func remove(_ habit: Habit) {
        habit.isPaused = true
        habit.name = habit.name.hasPrefix("Archived: ") ? habit.name : "Archived: " + habit.name
    }
}
