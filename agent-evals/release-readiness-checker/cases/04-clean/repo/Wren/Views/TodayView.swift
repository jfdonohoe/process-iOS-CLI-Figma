import PhotosUI
import SwiftUI
import SwiftData
import UserNotifications

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Entry.recordedAt, order: .reverse) private var entries: [Entry]
    @AppStorage("reminderHour") private var reminderHour = 21
    @State private var cover: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            List(entries) { entry in Text(entry.recordedAt, style: .date) }
                .navigationTitle("Today")
                .toolbar { PhotosPicker("Cover", selection: $cover, matching: .images) }
                .task { _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) }
                .onDisappear { try? context.save() }
        }
    }
}
