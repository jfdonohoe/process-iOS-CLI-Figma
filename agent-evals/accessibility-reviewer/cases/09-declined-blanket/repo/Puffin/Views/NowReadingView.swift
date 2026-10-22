import SwiftUI
import SwiftData

struct NowReadingView: View {
    @Query private var books: [Book]
    @State private var pulse = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("This week")
                        .font(.title)
                        .foregroundStyle(Color.slate)
                    HStack {
                        Circle()
                            .fill(Color.heather)
                            .frame(width: 10, height: 10)
                            .scaleEffect(pulse ? 1.6 : 1)
                            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
                        Text("Reading now")
                            .font(.headline)
                            .foregroundStyle(Color.ink)
                    }
                    .onAppear { pulse = true }
                    Button {
                        shareProgress()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    ForEach(books) { book in
                        HStack {
                            Circle()
                                .fill(book.isOverdue ? Color.red : Color.green)
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading) {
                                Text(book.title)
                                    .font(.body)
                                    .foregroundStyle(Color.ink)
                                Text("\(book.pagesRead) of \(book.pageCount) pages")
                                    .font(.footnote)
                                    .foregroundStyle(Color.mist)
                            }
                            Spacer()
                            if book.finished {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                                Text("Finished")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Link("Find your local library", destination: URL(string: "https://example.org")!)
                        .font(.subheadline)
                        .foregroundStyle(Color.moss)
                    Button {
                        logSession()
                    } label: {
                        Text("Log Reading")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Capsule().fill(Color.apricot))
                    }
                }
                .padding()
            }
            .navigationTitle("Now")
        }
    }

    private func logSession() {}
    private func shareProgress() {}
}
