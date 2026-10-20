import SwiftUI
import SwiftData

struct RootView: View {
    @Query(sort: \Session.createdAt, order: .reverse) private var sessions: [Session]

    var body: some View {
        TabView {
            NavigationStack {
                List(sessions) { session in
                    Text(session.title)
                }
                .navigationTitle("History")
            }
            .tabItem { Label("History", systemImage: "clock") }

            NavigationStack {
                Form {
                    UnitsSetting()
                    LabeledContent("Example") { WeightLabel(kilograms: 100) }
                }
                .navigationTitle("Settings")
            }
            .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
