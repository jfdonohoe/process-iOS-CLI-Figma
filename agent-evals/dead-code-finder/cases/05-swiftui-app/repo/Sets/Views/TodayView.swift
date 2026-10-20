import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: \Workout.date) private var workouts: [Workout]

    /// An unfinished workout to resume, shown above today's list.
    private var resumable: Workout? { nil }

    var body: some View {
        List {
            if let workout = resumable {
                ResumeCard(workout: workout)
            }
            ForEach(todays) { workout in
                Text(workout.title)
            }
        }
    }

    private var todays: [Workout] {
        workouts.filter { Calendar.current.isDateInToday($0.date) }
    }
}
