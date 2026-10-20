import SwiftUI
import SwiftData

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { HistoryScreen() }
                .tabItem { Label("History", systemImage: "clock") }
            NavigationStack { TodayScreen() }
                .tabItem { Label("Today", systemImage: "figure.strengthtraining.traditional") }
        }
    }
}
