import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hapticsOn") private var hapticsOn = true

    var body: some View {
        Form {
            Section {
                Toggle("Haptic pacing", isOn: $hapticsOn)
            }
            Section("Developer") {
                Button("Load sample sessions") { SampleSessions.insert(into: context) }
            }
            Section {
            } footer: {
                Text("Plover 1.3.0 (21)")
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Settings")
    }
}
