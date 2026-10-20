import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var books: [Book]
    @State private var showInfo = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(books.filter(\.finished).count)")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.ink)
                    Text("books finished")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
                Link("How stats are counted", destination: URL(string: "https://example.org/stats")!)
                    .font(.subheadline)
                    .foregroundStyle(Color.moss)
                List {
                    Section {
                        HStack {
                            Text("Pages this month")
                            Spacer()
                            Button {
                                showInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .frame(width: 34, height: 34)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("About this number")
                        }
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }
}
