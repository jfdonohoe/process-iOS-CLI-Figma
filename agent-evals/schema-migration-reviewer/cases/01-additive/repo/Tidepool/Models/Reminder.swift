import Foundation
import SwiftData

@Model
final class Reminder {
    var hour: Int
    var minute: Int
    var isEnabled: Bool

    init(hour: Int, minute: Int, isEnabled: Bool = true) {
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
    }
}
