import SwiftUI

struct SettingsView: View {
    private var versionLine: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let name = info["CFBundleDisplayName"] as? String ?? "Wren"
        let version = info["CFBundleShortVersionString"] as? String ?? "?"
        let build = info["CFBundleVersion"] as? String ?? "?"
        return "\(name) \(version) (\(build))"
    }

    var body: some View {
        Form {
            Section {
            } footer: {
                Text(versionLine).frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Settings")
    }
}
