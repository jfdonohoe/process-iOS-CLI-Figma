import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query private var books: [Book]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glow = false
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Image(decorative: "library-header")
                        .resizable()
                        .scaledToFit()
                }
                ForEach(books) { book in
                    NavigationLink(value: book.title) {
                        HStack(spacing: 12) {
                            ProgressDial(progress: book.progress)
                                .frame(width: 44, height: 44)
                            VStack(alignment: .leading) {
                                Text(book.title)
                                    .font(.custom("Georgia", size: 17))
                                    .foregroundStyle(Color.ink)
                                Text("\(book.pagesRead) of \(book.pageCount) pages")
                                    .font(.footnote)
                                    .foregroundStyle(Color.heather)
                            }
                            if book.isOverdue {
                                Label("Overdue", systemImage: "exclamationmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                Button {
                    showAdd = true
                } label: {
                    Label("Add Book", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Circle()
                        .fill(Color.heather)
                        .frame(width: 8, height: 8)
                        .opacity(glow ? 0.4 : 1)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 1).repeatForever(), value: glow)
                        .accessibilityHidden(true)
                    Text("Syncing your shelf")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .onAppear { glow = true }
            }
        }
    }
}
