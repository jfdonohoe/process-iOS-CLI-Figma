import SwiftUI

/// All entries of a session, one section each.
struct EntryList: View {
    let entries: [Entry]
    let isLocked: Bool
    @Binding var doneCount: Int
    var onSetDone: () -> Void

    var body: some View {
        ForEach(entries) { entry in
            EntrySection(entry: entry, isLocked: isLocked, doneCount: $doneCount, onSetDone: onSetDone)
        }
    }
}

/// One exercise and its sets.
struct EntrySection: View {
    let entry: Entry
    let isLocked: Bool
    @Binding var doneCount: Int
    var onSetDone: () -> Void

    var body: some View {
        Section(entry.name) {
            ForEach(entry.sets.sorted { $0.index < $1.index }) { set in
                SetRow(set: set, isLocked: isLocked, doneCount: $doneCount, onSetDone: onSetDone)
            }
        }
    }
}

/// One set. Tapping the circle marks it done and starts the rest timer.
struct SetRow: View {
    @Bindable var set: LoggedSet
    let isLocked: Bool
    @Binding var doneCount: Int
    var onSetDone: () -> Void
    @Environment(\.modelContext) private var context
    @State private var showingPlates = false

    private let weights: WeightFormatting = KilogramFormatter()

    var body: some View {
        HStack {
            Button {
                set.done.toggle()
                doneCount += set.done ? 1 : -1
                try? context.save()
                if set.done { onSetDone() }
            } label: {
                Image(systemName: set.done ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.borderless)
            .disabled(isLocked)

            Text("Set \(set.index + 1): \(set.reps) × \(weights.string(forKilograms: set.weightKg))")
            Spacer()

            if set.weightKg > PlateCalculator.barKg {
                Button {
                    showingPlates = true
                } label: {
                    Image(systemName: "circle.grid.2x1")
                }
                .buttonStyle(.borderless)
            }
        }
        .sheet(isPresented: $showingPlates) {
            PlateSheet(targetKg: set.weightKg)
        }
    }
}

struct PlateSheet: View {
    let targetKg: Double

    var body: some View {
        List(PlateCalculator.platesPerSide(for: targetKg)) { load in
            HStack {
                Circle().fill(load.color).frame(width: 14, height: 14)
                Text("\(load.label) kg")
                Spacer()
                Text("× \(load.count)")
            }
        }
        .navigationTitle("Per side")
        .presentationDetents([.medium])
    }
}
