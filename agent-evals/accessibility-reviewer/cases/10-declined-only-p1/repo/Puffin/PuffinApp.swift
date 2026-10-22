import SwiftUI
import SwiftData

@main
struct PuffinApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                StatsView()
                    .tabItem { Label("Stats", systemImage: "chart.bar") }
            }
        }
        .modelContainer(for: Book.self)
    }
}
