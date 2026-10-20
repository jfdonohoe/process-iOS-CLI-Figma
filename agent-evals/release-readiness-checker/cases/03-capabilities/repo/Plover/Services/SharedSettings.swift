import Foundation

/// Settings shared with the widget extension.
enum SharedSettings {
    static let defaults = UserDefaults(suiteName: "group.com.example.plover.widget")!

    static var breathsPerMinute: Double {
        get { defaults.object(forKey: "bpm") as? Double ?? 6 }
        set { defaults.set(newValue, forKey: "bpm") }
    }
}
