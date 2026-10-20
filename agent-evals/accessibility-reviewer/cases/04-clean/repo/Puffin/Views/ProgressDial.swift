import SwiftUI

struct ProgressDial: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.ink.opacity(0.15), lineWidth: 5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.heather, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
    }
}
