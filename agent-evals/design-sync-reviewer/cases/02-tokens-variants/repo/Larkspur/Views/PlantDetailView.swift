import SwiftUI

struct PlantDetailView: View {
    let plant: Plant
    private var history: [Date] { plant.lastWatered.map { [$0] } ?? [] }

    var body: some View {
        List {
            Section {
                LabeledContent("Last watered", value: plant.lastWatered?.formatted(.relative(presentation: .named)) ?? "Never")
                LabeledContent("Water every", value: "\(plant.waterEveryDays) days")
                if plant.isOverdue {
                    Text("Overdue")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(red: 0.76, green: 0.42, blue: 0.11))
                }
            }

            Section {
                Text("Next watering")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text(plant.notes.isEmpty ? "No notes" : plant.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Text("History")
                    .font(.headline)
                ForEach(history, id: \.self) { date in
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                }
            }

            Section {
                PrimaryButton("Mark as Watered", fill: true) { plant.lastWatered = .now }
                Button("Delete Plant", role: .destructive) { }
                    .foregroundStyle(Color.leaf)
            }
        }
        .navigationTitle(plant.name)
    }
}
