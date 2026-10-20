import SwiftUI

struct SettingsView: View {
    @AppStorage("reminders") private var reminders = true

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Daily reminder", isOn: $reminders)
                Text("Puffin keeps everything on this iPhone.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mist)
            }
            .navigationTitle("Settings")
            .toolbar {
                Button {
                } label: {
                    Image("help-bubble")
                }
            }
        }
    }
}
