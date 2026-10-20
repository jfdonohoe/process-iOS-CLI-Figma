import SwiftUI
import SwiftData

@main
struct LiftsApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Schema.lifts)
        } catch {
            fatalError("Could not open the Lifts store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .task { await seedIfEmpty() }
        }
        .modelContainer(container)
    }

    @MainActor
    private func seedIfEmpty() async {
        let context = container.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<Routine>())) ?? 0
        guard count == 0 else { return }
        try? DemoData.seed(into: context)
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { HistoryScreen() }
                .tabItem { Label("History", systemImage: "clock") }
            NavigationStack { TodayScreen() }
                .tabItem { Label("Today", systemImage: "figure.strengthtraining.traditional") }
        }
    }
}

/// Today's session, if one is scheduled.
struct TodayScreen: View {
    @Query(sort: \Session.scheduledFor) private var sessions: [Session]

    var body: some View {
        if let next = sessions.first(where: { !$0.isLocked }) {
            SessionScreen(session: next)
        } else {
            ContentUnavailableView("Nothing scheduled", systemImage: "calendar")
        }
    }
}
