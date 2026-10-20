import SwiftUI

struct ArchiveRow: View {
    let workout: Workout
    var body: some View {
        HStack {
            Text(workout.title)
            Spacer()
            Text(workout.date, style: .date).foregroundStyle(.secondary)
        }
    }
}
