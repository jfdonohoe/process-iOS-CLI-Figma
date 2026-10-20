import SwiftUI
import SwiftData

@main
struct PuffinApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                LibraryView()
                    .tabItem { Label("Library", systemImage: "books.vertical") }
            }
        }
        .modelContainer(for: Book.self)
    }
}
