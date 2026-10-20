import SwiftUI

struct BookDetailView: View {
    @Bindable var book: Book
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Rating") {
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= book.rating ? "star.fill" : "star")
                                .foregroundStyle(Color.heather)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                                .onTapGesture { book.rating = star }
                        }
                    }
                }
                Section {
                    Button {
                        share()
                    } label: {
                        Label("Share Progress", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        book.pagesRead = 0
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Start Over")
                        }
                    }
                    Button(role: .destructive) {
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Remove from Reading")
                }
            }
            .navigationTitle(book.title)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }

    private func share() {}
}
