import SwiftUI
import SwiftData

/// The in-workout screen. Holds the session model directly, so it reads
/// `session.updatedAt` to re-render when a set inside it changes.
struct LiveSessionView: View {
    let session: Session
    @Environment(\.modelContext) private var context
    @State private var saveError: String?

    var body: some View {
        let _ = session.updatedAt
        let entries = session.entries.sorted { $0.order < $1.order }
        List {
            Section {
                Text("\(doneCount) of \(totalCount) sets done")
                    .font(.headline)
            }
            ForEach(entries) { entry in
                Section(entry.name) {
                    ForEach(entry.sets.sorted { $0.index < $1.index }) { set in
                        SetRow(set: set, onToggle: { toggle(set) }, onReps: { adjustReps(set, by: $0) })
                    }
                }
            }
        }
        .navigationTitle(session.title)
        .alert("Couldn't save", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveError ?? "")
        }
    }

    private func toggle(_ set: LoggedSet) {
        guard !session.isLocked else { return }
        set.done.toggle()
        session.updatedAt = .now
        do { try context.save() } catch { saveError = error.localizedDescription }
    }

    private func adjustReps(_ set: LoggedSet, by delta: Int) {
        guard !session.isLocked else { return }
        set.reps = max(0, set.reps + delta)
        session.updatedAt = .now
        do { try context.save() } catch { saveError = error.localizedDescription }
    }

    private var doneCount: Int { session.entries.flatMap(\.sets).filter(\.done).count }
    private var totalCount: Int { session.entries.flatMap(\.sets).count }
}
