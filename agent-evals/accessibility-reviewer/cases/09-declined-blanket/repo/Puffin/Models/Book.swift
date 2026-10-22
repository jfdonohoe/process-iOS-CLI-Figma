import Foundation
import SwiftData

@Model
final class Book {
    var title: String
    var author: String
    var pagesRead: Int
    var pageCount: Int
    var rating: Int = 0
    var dueBack: Date?
    var finished: Bool = false

    init(title: String, author: String, pagesRead: Int = 0, pageCount: Int) {
        self.title = title
        self.author = author
        self.pagesRead = pagesRead
        self.pageCount = pageCount
    }

    var progress: Double { pageCount == 0 ? 0 : Double(pagesRead) / Double(pageCount) }
    var isOverdue: Bool { (dueBack ?? .distantFuture) < .now }
}
