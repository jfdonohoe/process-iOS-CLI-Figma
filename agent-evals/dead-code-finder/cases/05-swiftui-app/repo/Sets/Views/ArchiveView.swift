import SwiftUI

/// Full-screen list of finished workouts.
struct ArchiveView: View {
    let workouts: [Workout]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(workouts) { ArchiveRow(workout: $0) }
                .toolbar { Button("Done") { dismiss() } }
        }
    }
}

#Preview {
    ArchiveView(workouts: [])
}
