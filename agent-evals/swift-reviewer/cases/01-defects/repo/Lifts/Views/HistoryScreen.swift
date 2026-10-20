import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct HistoryScreen: View {
    @Query(sort: \Session.createdAt, order: .reverse) private var sessions: [Session]
    @State private var showingImporter = false
    @State private var showingExport = false
    @State private var exporting: Session?
    var onRepeat: (Session) -> Void = { _ in }
    var onImport: (URL) -> Void = { _ in }

    var body: some View {
        List(sessions) { session in
            HStack {
                Text(session.title)
                Spacer()
                Button("Share") { exporting = session; showingExport = true }
                    .buttonStyle(.borderless)
                Button("Repeat") { onRepeat(session) }
                    .buttonStyle(.borderless)
            }
        }
        .toolbar {
            Button("Import") { showingImporter = true }
            Button("Export") { exporting = nil; showingExport = true }
        }
        .sheet(isPresented: $showingExport) {
            ExportSheet(session: exporting)
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.commaSeparatedText]) { result in
            if case .success(let url) = result { onImport(url) }
        }
    }
}

/// Exports one session, or all of them when `session` is nil.
struct ExportSheet: View {
    let session: Session?
    var body: some View { Text(session.map { "Export \($0.title)" } ?? "Export all") }
}
