import SwiftUI

struct WateringView: View {
    enum Phase: String, CaseIterable {
        case countdown
        case done
    }

    let plant: Plant
    @State var phase: Phase = .countdown
    @State private var secondsLeft = 30
    @AppStorage("remindTomorrow") private var remindTomorrow = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                switch phase {
                case .countdown:
                    Text("\(secondsLeft)s")
                        .font(.largeTitle.bold())
                        .monospacedDigit()
                    Text("Water slowly until it drains from the bottom.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                case .done:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.leaf)
                    Text("Watered")
                        .font(.title2.bold())
                    Toggle("Remind me tomorrow", isOn: $remindTomorrow)
                }
            }
            .padding()
            .navigationTitle(plant.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Skip") { dismiss() } }
            }
        }
    }
}
