import SwiftUI
import SwiftData

@main
struct PuffinApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ShelfView()
                    .tabItem { Label("Shelf", systemImage: "books.vertical") }
            }
        }
        .modelContainer(for: Book.self)
    }
}
