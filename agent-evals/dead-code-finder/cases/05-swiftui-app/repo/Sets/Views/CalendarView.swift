import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \Workout.date) private var workouts: [Workout]
    @State private var selected: Workout?
    @State private var showingArchive = false

    var body: some View {
        NavigationStack {
            List(workouts) { workout in
                Button(workout.title) { selected = workout }
            }
            .navigationTitle("Calendar")
        }
        .sheet(item: $selected) { workout in
            DayDetailView(workout: workout)
        }
        .fullScreenCover(isPresented: $showingArchive) {
            ArchiveView(workouts: workouts.filter(\.finished))
        }
    }
}
