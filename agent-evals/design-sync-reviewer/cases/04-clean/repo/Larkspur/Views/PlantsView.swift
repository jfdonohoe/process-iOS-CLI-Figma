import SwiftUI
import SwiftData

struct PlantsView: View {
    @Query(sort: \Plant.name) private var plants: [Plant]

    var body: some View {
        NavigationStack {
            List(plants) { plant in
                NavigationLink(value: plant) { PlantRow(plant: plant) }
            }
            .navigationTitle("Plants")
            .navigationDestination(for: Plant.self) { PlantDetailView(plant: $0) }
        }
    }
}
