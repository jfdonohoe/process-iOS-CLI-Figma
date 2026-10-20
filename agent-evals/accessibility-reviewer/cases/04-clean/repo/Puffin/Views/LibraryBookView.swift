import SwiftUI

struct LibraryBookView: View {
    @Bindable var book: Book
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .title) private var heroSize = 56

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "book.closed")
                    .font(.system(size: heroSize))
                    .foregroundStyle(Color.heather)
                    .accessibilityHidden(true)
                Text(book.title)
                    .font(.system(.title2, design: .serif))
                    .foregroundStyle(Color.ink)
                Stepper("Pages read: \(book.pagesRead)", value: $book.pagesRead, in: 0...book.pageCount)
                Button {
                    dismiss()
                } label: {
                    Text("Save")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Capsule().fill(Color.plum))
                }
            }
            .padding()
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.bold))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(.thinMaterial))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Close")
        }
    }
}
