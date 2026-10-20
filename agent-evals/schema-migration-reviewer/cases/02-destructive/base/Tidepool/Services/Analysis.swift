import Foundation
import SwiftData

@MainActor
enum Analysis {
    static let algorithmVersion = 2

    static func analyze(_ session: PracticeSession, in context: ModelContext) throws {
        let calm = DerivedMetric(sessionID: session.externalID, name: "calm",
                                 value: Double(session.averageHeartRate) / 100, algorithmVersion: algorithmVersion)
        context.insert(calm)
        try context.save()
    }
}
