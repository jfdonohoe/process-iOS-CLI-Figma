import SwiftUI
import SwiftData

@main
struct PuffinApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                NowReadingView()
                    .tabItem { Label("Now", systemImage: "book") }
                GoalCelebration()
                    .tabItem { Label("Goals", systemImage: "flag") }
            }
        }
        .modelContainer(for: Book.self)
    }
}
