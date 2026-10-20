import SwiftUI
import SwiftData

@main
struct MartenApp: App {
    var body: some Scene {
        WindowGroup {
            TodayView()
            #if DEBUG
                .task { SampleHabits.seedIfRequested() }
            #endif
        }
        .modelContainer(for: [Habit.self, Completion.self])
    }
}
