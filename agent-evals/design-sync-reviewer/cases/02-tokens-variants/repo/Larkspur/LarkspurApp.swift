import SwiftUI
import SwiftData

@main
struct LarkspurApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                PlantsView()
                    .tabItem { Label("Plants", systemImage: "leaf") }
                RemindersView()
                    .tabItem { Label("Reminders", systemImage: "bell") }
            }
            .tint(Color.leaf)
        }
        .modelContainer(for: Plant.self)
    }
}
