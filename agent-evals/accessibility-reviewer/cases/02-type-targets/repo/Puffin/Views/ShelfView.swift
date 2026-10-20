import SwiftUI
import SwiftData

struct ShelfView: View {
    @Query private var books: [Book]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))]) {
                    ForEach(books) { book in
                        VStack(alignment: .leading) {
                            NavigationLink {
                                BookNotesView(book: book)
                            } label: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.heather.opacity(0.2))
                                    .frame(height: 180)
                            }
                            .accessibilityLabel("Notes for \(book.title)")
                            HStack {
                                Text(book.title)
                                    .font(.subheadline)
                                Spacer()
                                Button {
                                    book.finished.toggle()
                                } label: {
                                    Image(systemName: book.finished ? "checkmark.circle.fill" : "circle")
                                        .frame(width: 36, height: 36)
                                }
                                .accessibilityLabel(book.finished ? "Mark unread" : "Mark finished")
                                Button {
                                    book.rating = 0
                                } label: {
                                    Image(systemName: "star.slash")
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                                .accessibilityLabel("Clear rating")
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Shelf")
        }
    }
}
