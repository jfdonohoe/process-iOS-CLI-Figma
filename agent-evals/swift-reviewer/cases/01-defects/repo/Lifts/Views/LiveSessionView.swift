import SwiftUI
import SwiftData

/// The in-workout screen. Holds the session model directly.
struct LiveSessionView: View {
    let session: Session
    @Environment(\.modelContext) private var context

    var body: some View {
        let entries = session.entries.sorted { $0.order < $1.order }
        List {
            Section {
                Text("\(doneCount) of \(totalCount) sets done")
                    .font(.headline)
            }
            ForEach(entries) { entry in
                Section(entry.name) {
                    ForEach(entry.sets.sorted { $0.index < $1.index }) { set in
                        SetRow(set: set) {
                            set.done.toggle()
                            try? context.save()
                        }
                    }
                }
            }
        }
        .navigationTitle(session.title)
    }

    private var doneCount: Int { session.entries.flatMap(\.sets).filter(\.done).count }
    private var totalCount: Int { session.entries.flatMap(\.sets).count }
}
