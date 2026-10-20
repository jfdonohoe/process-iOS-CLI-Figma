import SwiftUI

/// Figma: Plant Row
struct PlantRow: View {
    let plant: Plant

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name)
                Text("Every \(plant.waterEveryDays) days")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if plant.isOverdue {
                Text("Overdue")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.thirsty)
            }
        }
    }
}
