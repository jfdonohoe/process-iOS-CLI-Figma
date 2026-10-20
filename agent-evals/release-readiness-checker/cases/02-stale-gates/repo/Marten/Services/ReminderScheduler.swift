import UserNotifications

enum ReminderScheduler {
    static func schedule(for habit: Habit) async {
        guard let time = habit.reminderTime else { return }
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        let content = UNMutableNotificationContent()
        content.title = habit.name
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
        let request = UNNotificationRequest(identifier: habit.id.uuidString, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
