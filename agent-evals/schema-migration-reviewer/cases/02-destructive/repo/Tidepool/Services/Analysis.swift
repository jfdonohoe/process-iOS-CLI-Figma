import Foundation
import SwiftData

@MainActor
enum Analysis {
    static let algorithmVersion = 3

    static func analyze(_ session: PracticeSession, in context: ModelContext) throws {
        let calm = DerivedMetric(sessionID: session.externalID, name: "calm",
                                 value: session.averageHeartRate / 90, algorithmVersion: algorithmVersion)
        context.insert(calm)
        try context.save()
    }

    /// Re-run analysis for every session so all metrics use the current algorithm.
    static func reanalyzeAll(in context: ModelContext) throws {
        try context.delete(model: DerivedMetric.self)
        for session in try context.fetch(FetchDescriptor<PracticeSession>()) {
            try analyze(session, in: context)
        }
    }
}
