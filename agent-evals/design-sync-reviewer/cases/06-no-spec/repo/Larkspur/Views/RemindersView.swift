import SwiftUI

struct RemindersView: View {
    @AppStorage("remindersOn") private var remindersOn = true

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Watering reminders", isOn: $remindersOn)
            }
            .navigationTitle("Reminders")
        }
    }
}
