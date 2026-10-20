import SwiftUI
import SwiftData

@main
struct PuffinApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ReadingListView()
                    .tabItem { Label("Reading", systemImage: "book") }
            }
        }
        .modelContainer(for: Book.self)
    }
}
