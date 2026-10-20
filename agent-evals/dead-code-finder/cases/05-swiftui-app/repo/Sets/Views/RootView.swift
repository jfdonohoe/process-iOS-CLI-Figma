import SwiftUI

struct RootView: View {
    @State private var importURL: URL?

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "figure.strengthtraining.traditional") }
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        // Opened from Files / AirDrop: sets://import?file=...
        .onOpenURL { url in importURL = url }
        .sheet(item: $importURL) { url in
            ImportView(url: url)
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
