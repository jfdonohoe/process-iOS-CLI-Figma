import SwiftUI

/// One set inside a List section: tap the check to mark done, or nudge the
/// rep count by one.
struct SetRow: View {
    let set: LoggedSet
    var onToggle: () -> Void
    var onReps: (Int) -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: set.done ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.borderless)
            Text("Set \(set.index + 1): \(set.reps) × \(set.weight, specifier: "%.1f")")
            Spacer()
            Button { onReps(-1) } label: { Image(systemName: "minus.circle") }
                .buttonStyle(.borderless)
            Button { onReps(1) } label: { Image(systemName: "plus.circle") }
                .buttonStyle(.borderless)
        }
    }
}
