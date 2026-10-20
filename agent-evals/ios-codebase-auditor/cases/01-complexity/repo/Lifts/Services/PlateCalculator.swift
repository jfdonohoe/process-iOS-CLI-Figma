import SwiftUI

/// Which plates to load on each side of a 20 kg bar to reach a target weight.
enum PlateCalculator {
    static let barKg = 20.0

    static let plateLabels = ["25", "20", "15", "10", "5", "2.5", "1.25"]
    static let plateKg: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]
    static let plateColors: [Color] = [.red, .blue, .yellow, .green, .white, .black, .gray]

    struct Load: Identifiable, Equatable {
        var id: String { label }
        let label: String
        let color: Color
        let count: Int
    }

    /// Heaviest plates first. Anything the smallest plate can't make up is dropped.
    static func platesPerSide(for targetKg: Double) -> [Load] {
        var remaining = max(0, (targetKg - barKg) / 2)
        var loads: [Load] = []
        for i in 0..<plateKg.count {
            let count = Int(remaining / plateKg[i])
            if count > 0 {
                loads.append(Load(label: plateLabels[i], color: plateColors[i], count: count))
                remaining -= Double(count) * plateKg[i]
            }
        }
        return loads
    }
}
