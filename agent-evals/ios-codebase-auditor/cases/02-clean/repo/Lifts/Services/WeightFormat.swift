import Foundation

/// Weights are stored in kilograms and shown in kilograms, with at most one decimal.
enum WeightFormat {
    static func label(kilograms: Double, locale: Locale = .current) -> String {
        kilograms.formatted(.number.precision(.fractionLength(0...1)).locale(locale)) + " kg"
    }
}
