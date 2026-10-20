import SwiftUI
import SwiftData
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }
}

@main
struct WrenApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    let container: ModelContainer = {
        let schema = Schema(versionedSchema: WrenSchemaV2.self)
        return try! ModelContainer(for: schema, migrationPlan: WrenMigrationPlan.self)
    }()

    var body: some Scene {
        WindowGroup {
            TodayView()
            #if DEBUG && targetEnvironment(simulator)
                .task { SampleEntries.seedIfRequested(container.mainContext) }
            #endif
        }
        .modelContainer(container)
    }
}
