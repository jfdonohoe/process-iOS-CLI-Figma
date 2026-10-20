import SwiftUI
import SwiftData

/// Finished and abandoned sessions, by month, with this week's repeated on top
/// so the current block is visible without scrolling.
struct HistoryScreen: View {
    @Query(sort: \Session.scheduledFor, order: .reverse) private var sessions: [Session]

    var body: some View {
        // Derived once per render. Training weeks count from the first session ever scheduled.
        let history = sessions.filter(\.isLocked)
        let thisWeek = HistoryStats.thisWeek(history, anchor: sessions.map(\.scheduledFor).min())
        let months = HistoryStats.sessionsByMonth(history)
        let counts = HistoryStats.doneSetsPerExercise(history)

        List {
            if !thisWeek.isEmpty {
                Section("This week") {
                    ForEach(thisWeek) { HistoryRow(session: $0) }
                }
            }
            ForEach(months) { group in
                Section(group.title) {
                    ForEach(group.sessions) { HistoryRow(session: $0) }
                }
            }
            if !counts.isEmpty {
                Section("Sets per exercise") {
                    ForEach(counts) { LabeledContent($0.name, value: "\($0.doneSets)") }
                }
            }
        }
        .navigationTitle("History")
    }
}

struct HistoryRow: View {
    let session: Session

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.title)
                Text(session.scheduledFor, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(session.doneSetCount)/\(session.totalSetCount)")
                .monospacedDigit()
        }
    }
}
