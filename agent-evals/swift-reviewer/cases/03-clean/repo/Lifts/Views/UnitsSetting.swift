import SwiftUI

/// Settings row for the display unit. Stored values never change; only how
/// they are shown.
struct UnitsSetting: View {
    @AppStorage("weightUnit") private var unit: WeightUnit = .kilograms

    var body: some View {
        Picker("Weight unit", selection: $unit) {
            ForEach(WeightUnit.allCases) { unit in
                Text(unit.symbol).tag(unit)
            }
        }
    }
}
