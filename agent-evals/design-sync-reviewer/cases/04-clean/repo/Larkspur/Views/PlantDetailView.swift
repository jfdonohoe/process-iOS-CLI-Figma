import SwiftUI

struct PlantDetailView: View {
    let plant: Plant

    var body: some View {
        List {
            LabeledContent("Water every", value: "\(plant.waterEveryDays) days")
        }
        .navigationTitle(plant.name)
    }
}
