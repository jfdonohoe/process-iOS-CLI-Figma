import SwiftUI
import SwiftData

@main
struct LarkspurApp: App {
    let container: ModelContainer = try! ModelContainer(for: Plant.self)

    var body: some Scene {
        WindowGroup {
            root
                .tint(Color.leaf)
                .task {
                    #if DEBUG && targetEnvironment(simulator)
                    SampleDataSeeder.seedIfRequested(into: container.mainContext)
                    #endif
                }
        }
        .modelContainer(container)
    }

    @ViewBuilder private var root: some View {
        #if DEBUG && targetEnvironment(simulator)
        if let phase = SampleDataSeeder.requestedFlow {
            WateringView(plant: Plant(name: "Monstera", location: "sample", waterEveryDays: 7), phase: phase)
        } else {
            tabs
        }
        #else
        tabs
        #endif
    }

    private var tabs: some View {
        TabView {
            PlantsView()
                .tabItem { Label("Plants", systemImage: "leaf") }
            RemindersView()
                .tabItem { Label("Reminders", systemImage: "bell") }
        }
    }
}
