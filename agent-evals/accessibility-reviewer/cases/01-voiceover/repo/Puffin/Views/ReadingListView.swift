import SwiftUI
import SwiftData

struct ReadingListView: View {
    @Query private var books: [Book]
    @State private var showAdd = false
    @State private var scanning = false
    @State private var selected: Book?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Image(decorative: "shelf-banner")
                        .resizable()
                        .scaledToFit()
                }
                ForEach(books) { book in
                    BookRow(book: book) { selected = book }
                }
            }
            .navigationTitle("Reading")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        scanning = true
                    } label: {
                        Image("barcode-scan")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Label("Add Book", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .sheet(item: $selected) { BookDetailView(book: $0) }
            .sheet(isPresented: $showAdd) { Text("Add") }
        }
    }
}
