import SwiftUI

struct RemindersView: View {
    @AppStorage("remindersOn") private var remindersOn = true
    @AppStorage("reminderHour") private var reminderHour = 8
    @State private var isConfirmingReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Watering reminders", isOn: $remindersOn)
                    Stepper("Remind at \(reminderHour):00", value: $reminderHour, in: 5...22)
                } footer: {
                    Text("Reminders arrive once a day, at most.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Skip reminders on weekends")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Plants don’t mind a short wait.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    PrimaryButton("Send a Test Reminder") { }
                    Button("Reset Reminders", role: .destructive) { isConfirmingReset = true }
                }
                #if DEBUG
                Section("Debug") {
                    Button("Fire reminder now") { }
                }
                #endif
            }
            .navigationTitle("Reminders")
        }
    }
}
