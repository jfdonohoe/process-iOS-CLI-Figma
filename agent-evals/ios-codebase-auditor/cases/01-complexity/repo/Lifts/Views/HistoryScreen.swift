import SwiftUI
import SwiftData

/// Finished and abandoned sessions, by month, with this week pulled out on top.
struct HistoryScreen: View {
    @Query(sort: \Session.scheduledFor, order: .reverse) private var sessions: [Session]
    @State private var sharing: Session?

    private let weights: WeightFormatting = KilogramFormatter()

    private var history: [Session] { sessions.filter(\.isLocked) }

    /// Training weeks are 7-day blocks counted from the first session ever scheduled.
    private var thisWeek: [Session] {
        guard let anchor = sessions.last?.scheduledFor else { return [] }
        let calendar = Calendar.current
        let current = HistoryStats.weekBlock(of: .now, from: anchor, calendar: calendar)
        return history.filter { HistoryStats.weekBlock(of: $0.scheduledFor, from: anchor, calendar: calendar) == current }
    }

    var body: some View {
        List {
            if !thisWeek.isEmpty {
                Section("This week") {
                    ForEach(thisWeek) { session in
                        HistoryRow(session: session) { sharing = session }
                    }
                }
            }
            ForEach(HistoryStats.sessionsByMonth(history)) { group in
                Section(group.title) {
                    ForEach(group.sessions) { session in
                        HistoryRow(session: session) { sharing = session }
                    }
                }
            }
            Section("Sets per exercise") {
                let counts = HistoryStats.doneSetsPerExercise(history)
                ForEach(counts.keys.sorted(), id: \.self) { name in
                    LabeledContent(name, value: "\(counts[name] ?? 0)")
                }
            }
        }
        .navigationTitle("History")
        .sheet(item: $sharing) { session in
            ShareSheet(session: session, weights: weights)
        }
    }
}

struct HistoryRow: View {
    let session: Session
    var onShare: () -> Void

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
            Button("Share", action: onShare)
                .buttonStyle(.borderless)
        }
    }
}

struct ShareSheet: View {
    let session: Session
    let weights: WeightFormatting
    @State private var format = ExportFormat.csv

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Picker("Format", selection: $format) {
                    ForEach(ExportFormat.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                ScrollView {
                    Text(format.exporter.export(session, weights: weights))
                        .font(.system(.footnote, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .navigationTitle("Share \(session.title)")
            .toolbar {
                ShareLink(item: format.exporter.export(session, weights: weights))
            }
        }
    }
}
