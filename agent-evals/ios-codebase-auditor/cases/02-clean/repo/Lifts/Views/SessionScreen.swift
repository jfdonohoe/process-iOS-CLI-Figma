import SwiftUI
import SwiftData

/// The in-workout screen: a progress header and the entries.
struct SessionScreen: View {
    let session: Session
    @Environment(\.modelContext) private var context
    @State private var saveError: String?

    var body: some View {
        List {
            Section {
                Text("\(session.doneSetCount) of \(session.totalSetCount) sets done")
                    .font(.headline)
            }
            ForEach(session.orderedEntries) { entry in
                Section(entry.name) {
                    ForEach(entry.orderedSets) { set in
                        SetRow(set: set, isLocked: session.isLocked) {
                            attempt { try SessionEditing.toggle(set, in: context) }
                        }
                    }
                }
            }
        }
        .navigationTitle(session.title)
        .toolbar {
            if !session.isLocked {
                Button("Finish") {
                    attempt { try SessionEditing.finish(session, in: context) }
                }
            }
        }
        .alert("Couldn't save", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
    }

    private func attempt(_ change: () throws -> Void) {
        do { try change() } catch { saveError = error.localizedDescription }
    }
}

/// One set. Tapping the circle marks it done.
struct SetRow: View {
    let set: LoggedSet
    let isLocked: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: set.done ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.borderless)
            .disabled(isLocked)
            .accessibilityLabel(set.done ? "Done" : "Not done")

            Text("Set \(set.index + 1): \(set.reps) × \(WeightFormat.label(kilograms: set.weightKg))")
            Spacer()
        }
    }
}
