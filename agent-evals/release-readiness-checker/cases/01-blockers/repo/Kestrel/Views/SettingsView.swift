import SwiftUI

struct SettingsView: View {
    @AppStorage("useMiles") private var useMiles = false

    var body: some View {
        Form {
            Toggle("Show distances in miles", isOn: $useMiles)
        }
        .navigationTitle("Settings")
    }
}
