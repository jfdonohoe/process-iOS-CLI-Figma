import SwiftUI

struct DayDetailView: View {
    let workout: Workout
    var body: some View {
        Text(workout.title)
    }
}
