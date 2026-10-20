import SwiftUI
import SwiftData

struct PlantsView: View {
    @Query(sort: \Plant.name) private var plants: [Plant]

    var body: some View {
        NavigationStack {
            List(plants) { plant in
                PlantRow(plant: plant)
            }
            .navigationTitle("Plants")
        }
    }
}
