import SwiftUI
import SwiftData

@main
struct SetsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: Workout.self)
    }
}
