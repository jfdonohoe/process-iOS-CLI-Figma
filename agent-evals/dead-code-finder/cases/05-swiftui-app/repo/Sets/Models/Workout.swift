import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    var title: String
    var date: Date
    var finished: Bool

    init(title: String, date: Date) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.finished = false
    }
}
