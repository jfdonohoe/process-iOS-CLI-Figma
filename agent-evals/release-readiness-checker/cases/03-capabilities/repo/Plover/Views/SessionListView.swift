import SwiftUI
import SwiftData

struct SessionListView: View {
    @Query(sort: \BreathSession.startedAt, order: .reverse) private var sessions: [BreathSession]
    @AppStorage("lastPace") private var lastPace = 6.0

    var body: some View {
        NavigationStack {
            List(sessions) { session in Text("\(session.minutes) min") }
                .navigationTitle("Sessions")
                .toolbar { NavigationLink("Settings") { SettingsView() } }
        }
    }
}
