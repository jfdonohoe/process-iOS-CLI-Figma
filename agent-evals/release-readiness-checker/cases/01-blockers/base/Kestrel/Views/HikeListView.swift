import SwiftUI
import SwiftData

struct HikeListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Hike.startedAt, order: .reverse) private var hikes: [Hike]
    @State private var search = ""

    private var shown: [Hike] {
        search.isEmpty ? hikes : hikes.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(shown) { hike in
                    NavigationLink(hike.name) { TrailDetailView(hike: hike) }
                }
                .onDelete(perform: delete)
            }
            .searchable(text: $search)
            .navigationTitle("Hikes")
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(hikes[index]) }
    }
}
