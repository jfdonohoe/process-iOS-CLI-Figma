import Foundation

/// Everything the app needs at launch, wired together.
public struct AppEnvironment {
    public let store: SessionStore
    public let stats: StatsService

    public static func make() -> AppEnvironment {
        let store = SessionStore()
        let stats = StatsService()
        stats.attach(to: store)
        return AppEnvironment(store: store, stats: stats)
    }
}
