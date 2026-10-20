import SwiftUI

struct BookNotesView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .body) private var noteSize = 16

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.heather)
                    .accessibilityHidden(true)
                Text(book.title)
                    .font(.system(.title2, design: .serif))
                Text("Notes and highlights you've saved while reading this book.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                Text("“A reader lives a thousand lives before he dies.”")
                    .font(.custom("Georgia", fixedSize: 18))
                Text("Your notes")
                    .font(.custom("Georgia", size: 17))
                Text("Tap a highlight to add a note.")
                    .font(.system(size: noteSize))
            }
            .padding()
        }
        .dynamicTypeSize(...DynamicTypeSize.large)
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.bold))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.thinMaterial))
            }
            .accessibilityLabel("Close")
            .padding(8)
        }
    }
}
