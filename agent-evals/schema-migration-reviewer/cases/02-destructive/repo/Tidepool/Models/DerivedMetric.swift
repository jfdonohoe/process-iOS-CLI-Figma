import Foundation
import SwiftData

@Model
final class DerivedMetric {
    var sessionID: String
    var name: String
    var value: Double
    var algorithmVersion: Int

    init(sessionID: String, name: String, value: Double, algorithmVersion: Int) {
        self.sessionID = sessionID
        self.name = name
        self.value = value
        self.algorithmVersion = algorithmVersion
    }
}
