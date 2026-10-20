import SwiftUI
import SwiftData

struct OverdueView: View {
    @Query(sort: \Plant.name) private var plants: [Plant]

    private var overdue: [Plant] { plants.filter(\.isOverdue) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(overdue) { plant in
                        PlantRow(plant: plant)
                    }
                } header: {
                    Text("\(overdue.count) need water")
                        .textCase(nil)
                        .foregroundStyle(Color(red: 0xC2 / 255, green: 0x6A / 255, blue: 0x1B / 255))
                } footer: {
                    Text("A plant is overdue the day after its watering date.")
                        .font(.caption)
                }
            }
            .navigationTitle("Overdue")
        }
    }
}
