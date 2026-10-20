import Foundation

enum WeightUnit: String, CaseIterable, Identifiable {
    case kilograms, pounds
    var id: String { rawValue }
    var symbol: String { self == .kilograms ? "kg" : "lb" }
}

/// `LoggedSet.weight` is always kilograms; this converts it for display only.
enum WeightFormat {
    static let poundsPerKilogram = 1 / 0.45359237

    static func display(_ kilograms: Double, in unit: WeightUnit) -> String {
        let value = unit == .kilograms ? kilograms : kilograms * poundsPerKilogram
        return value.formatted(.number.precision(.fractionLength(0...1))) + " " + unit.symbol
    }
}
