import Foundation
import SwiftData

@Model
final class PracticeSession {
    @Attribute(.unique) var externalID: String
    var startedAt: Date
    var title: String
    @Attribute(originalName: "notes") var journal: String
    var averageHeartRate: Double
    var kind: PracticeKind

    var displayTitle: String { title.isEmpty ? kind.rawValue : title }

    init(externalID: String, startedAt: Date, title: String, kind: PracticeKind) {
        self.externalID = externalID
        self.startedAt = startedAt
        self.title = title
        self.journal = ""
        self.averageHeartRate = 0
        self.kind = kind
    }
}
