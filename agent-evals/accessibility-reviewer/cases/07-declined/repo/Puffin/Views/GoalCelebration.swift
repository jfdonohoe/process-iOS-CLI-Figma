import SwiftUI

struct GoalCelebration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spin = false
    @State private var shown = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "rosette")
                .font(.largeTitle)
                .foregroundStyle(Color.heather)
                .rotationEffect(.degrees(spin ? 360 : 0))
                .animation(reduceMotion ? nil : .linear(duration: 4).repeatForever(autoreverses: false), value: spin)
                .accessibilityHidden(true)
            Text("Goal reached")
                .font(.title3.bold())
                .foregroundStyle(Color.ink)
            Button("Keep Going") {
                withAnimation(.spring) { shown.toggle() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.plum)
        }
        .onAppear { spin = true }
    }
}
