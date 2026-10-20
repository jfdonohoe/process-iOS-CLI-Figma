import SwiftUI
import SwiftData

/// The in-workout screen: a header with progress, the entries, a rest timer.
struct SessionScreen: View {
    @Bindable var session: Session
    @Environment(\.modelContext) private var context
    @State private var doneCount = 0
    @State private var restTimer = RestTimerModel(total: 90)

    private var sortedEntries: [Entry] { session.entries.sorted { $0.order < $1.order } }

    var body: some View {
        List {
            Section {
                Text("\(doneCount) of \(session.totalSetCount) sets done")
                    .font(.headline)
                RestTimerRow(model: restTimer)
            }
            EntryList(entries: sortedEntries, isLocked: session.isLocked, doneCount: $doneCount) {
                restTimer.start()
            }
        }
        .navigationTitle(session.title)
        .onAppear { doneCount = session.doneSetCount }
        .toolbar {
            if !session.isLocked {
                Button("Finish") {
                    if session.startedAt == nil { session.startedAt = .now }
                    session.finishedAt = .now
                    try? context.save()
                }
            }
        }
    }
}

struct RestTimerRow: View {
    let model: RestTimerModel

    var body: some View {
        HStack {
            Label("Rest", systemImage: "timer")
            Spacer()
            Text(model.label)
                .monospacedDigit()
                .foregroundStyle(model.isFinished ? .secondary : .primary)
        }
        .task(id: model.isRunning) {
            guard model.isRunning else { return }
            while !Task.isCancelled, model.isRunning {
                try? await Task.sleep(for: .seconds(1))
                model.tick()
            }
        }
    }
}
