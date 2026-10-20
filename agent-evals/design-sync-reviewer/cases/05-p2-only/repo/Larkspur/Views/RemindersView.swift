import SwiftUI

struct RemindersView: View {
    @AppStorage("remindersOn") private var remindersOn = true

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Get Watering Reminders!!", isOn: $remindersOn)
            }
            .navigationTitle("Reminder Settings")
        }
    }
}
