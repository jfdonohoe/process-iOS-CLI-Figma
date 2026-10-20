import SwiftUI
import SwiftData

struct AddPlantView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var location = ""
    @State private var waterEveryDays = 7

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Stepper("Water every \(waterEveryDays) days", value: $waterEveryDays, in: 1...60)
                TextField("Location", text: $location)
            }
            .navigationTitle("Add Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        context.insert(Plant(name: name, location: location, waterEveryDays: waterEveryDays))
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
