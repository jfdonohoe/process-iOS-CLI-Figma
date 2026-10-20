import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct HistoryScreen: View {
    @Query(sort: \Session.createdAt, order: .reverse) private var sessions: [Session]

    /// One presentation for the whole screen, so two can never collide.
    enum Route: Identifiable {
        case exportAll, share(Session), details(Session)
        var id: String {
            switch self {
            case .exportAll: return "export"
            case .share(let s): return "share-" + s.id.uuidString
            case .details(let s): return "details-" + s.id.uuidString
            }
        }
    }
    @State private var route: Route?

    var body: some View {
        List(sessions) { session in
            HStack {
                Text(session.title)
                Spacer()
                Button("Share") { route = .share(session) }
                    .buttonStyle(.borderless)
                Button("Details") { route = .details(session) }
                    .buttonStyle(.borderless)
            }
        }
        .toolbar {
            Button("Export") { route = .exportAll }
        }
        .sheet(item: $route) { route in
            switch route {
            case .exportAll: ExportSheet(session: nil)
            case .share(let s): ExportSheet(session: s)
            case .details(let s): Text(s.title)
            }
        }
    }
}

/// Exports one session, or all of them when `session` is nil.
struct ExportSheet: View {
    let session: Session?
    var body: some View { Text(session.map { "Export \($0.title)" } ?? "Export all") }
}
