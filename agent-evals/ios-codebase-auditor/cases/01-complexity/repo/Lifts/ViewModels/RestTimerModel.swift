import Foundation
import Observation

/// Counts down the rest between sets. The view calls `tick()` once a second.
@Observable
final class RestTimerModel {
    let total: Int
    private(set) var remaining: Int

    init(total: Int) {
        self.total = total
        self.remaining = total
    }

    private(set) var isRunning = false
    var isFinished: Bool { remaining == 0 }

    func start() { remaining = total; isRunning = true }
    func reset() { remaining = total; isRunning = false }

    func tick() {
        guard remaining > 0 else { return }
        remaining -= 1
        if remaining == 0 { isRunning = false }
    }

    /// The countdown as m:ss.
    var label: String {
        if remaining >= 600 {
            return "\(remaining / 60):" + String(format: "%02d", remaining % 60)
        }
        if remaining >= 60 {
            return "\(remaining / 60):" + String(format: "%02d", remaining % 60)
        }
        if remaining >= 10 {
            return "0:\(remaining)"
        }
        return "0:0\(remaining)"
    }
}
