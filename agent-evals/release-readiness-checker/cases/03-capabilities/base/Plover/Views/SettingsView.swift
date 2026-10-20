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
        }
        .navigationTitle("Settings")
    }
}
