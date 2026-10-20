import SwiftUI
import SwiftData

@main
struct PuffinApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                GoalsView()
                    .tabItem { Label("Goals", systemImage: "flag") }
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gear") }
            }
        }
        .modelContainer(for: Book.self)
    }
}
