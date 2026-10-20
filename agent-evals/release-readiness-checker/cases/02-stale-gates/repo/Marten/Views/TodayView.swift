import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(filter: #Predicate<Habit> { !$0.isPaused }, sort: \Habit.createdAt) private var habits: [Habit]
    @AppStorage("showCompleted") private var showCompleted = true

    var body: some View {
        NavigationStack {
            List(habits) { habit in Text(habit.name) }
                .navigationTitle("Today")
        }
    }
}
