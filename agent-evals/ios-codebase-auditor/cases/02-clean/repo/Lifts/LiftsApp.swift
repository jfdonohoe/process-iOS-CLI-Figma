import SwiftUI
import SwiftData

@main
struct LiftsApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Schema.lifts, migrationPlan: LiftsMigrationPlan.self)
        } catch {
            fatalError("Could not open the Lifts store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
