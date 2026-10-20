import SwiftUI

struct ResumeCard: View {
    let workout: Workout
    var body: some View {
        VStack(alignment: .leading) {
            Text("Resume").font(.caption)
            Text(workout.title).font(.headline)
        }
    }
}

#Preview {
    ResumeCard(workout: Workout(title: "Push", date: .now))
}
