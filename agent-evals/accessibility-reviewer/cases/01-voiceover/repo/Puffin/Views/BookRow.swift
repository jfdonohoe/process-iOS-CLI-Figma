import SwiftUI

struct BookRow: View {
    let book: Book
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ProgressRing(progress: book.progress)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading) {
                Text(book.title)
                    .font(.headline)
                    .foregroundStyle(Color.ink)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { onOpen() }
    }
}
