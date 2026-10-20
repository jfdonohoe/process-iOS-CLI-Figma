import Foundation
import SwiftData

@Model
final class PracticeSession {
    var externalID: String
    var startedAt: Date
    var label: String
    var notes: String
    var averageHeartRate: Int
    var kind: PracticeKind

    init(externalID: String, startedAt: Date, label: String, kind: PracticeKind) {
        self.externalID = externalID
        self.startedAt = startedAt
        self.label = label
        self.notes = ""
        self.averageHeartRate = 0
        self.kind = kind
    }
}
