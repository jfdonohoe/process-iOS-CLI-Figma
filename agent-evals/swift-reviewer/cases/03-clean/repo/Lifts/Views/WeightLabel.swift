import SwiftUI

/// Shows a stored weight in the unit chosen in Settings.
struct WeightLabel: View {
    let kilograms: Double
    @AppStorage("weightUnit") private var unit: WeightUnit = .kilograms

    var body: some View {
        Text(WeightFormat.display(kilograms, in: unit))
            .monospacedDigit()
    }
}
