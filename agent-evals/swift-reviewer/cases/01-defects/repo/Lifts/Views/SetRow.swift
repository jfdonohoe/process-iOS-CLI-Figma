import SwiftUI

/// One set inside a List section: tap the check to mark done, tap the
/// pencil to edit reps and weight.
struct SetRow: View {
    let set: LoggedSet
    var onToggle: () -> Void
    @State private var editing = false

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: set.done ? "checkmark.circle.fill" : "circle")
            }
            Text("Set \(set.index + 1): \(set.reps) × \(set.weight, specifier: "%.1f")")
            Spacer()
            Button {
                editing = true
            } label: {
                Image(systemName: "pencil")
            }
        }
        .sheet(isPresented: $editing) {
            SetEditor(set: set)
        }
    }
}

struct SetEditor: View {
    @Bindable var set: LoggedSet
    var body: some View {
        Form {
            Stepper("Reps \(set.reps)", value: $set.reps, in: 0...100)
        }
    }
}
