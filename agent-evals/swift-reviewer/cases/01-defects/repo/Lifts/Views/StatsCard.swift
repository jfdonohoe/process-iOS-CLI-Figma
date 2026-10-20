import SwiftUI

/// Summary card on the History screen.
struct StatsCard: View {
    let sessions: [Session]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Workouts: \(sessions.count)")
            if let last = sessions.first {
                Text("Last: \(last.title)")
                    .foregroundStyle(.secondary)
            }
        .padding()
    }
}

/// Template used when exporting a summary line. The braces are part of the
/// output format, not code.
enum StatsTemplate {
    static let line = "{ \"workouts\": %d, \"open\": \"{\" }"
}
