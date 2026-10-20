import SwiftUI
import SwiftData

@main
struct KestrelApp: App {
    var body: some Scene {
        WindowGroup {
            HikeListView()
            #if DEBUG
                .task { SampleTrails.seedIfRequested() }
            #endif
        }
        .modelContainer(for: Hike.self)
    }
}
