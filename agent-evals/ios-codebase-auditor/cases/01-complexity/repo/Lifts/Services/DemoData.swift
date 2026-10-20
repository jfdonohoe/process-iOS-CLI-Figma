import Foundation
import SwiftData

/// The sample content a first launch shows. One routine and one finished
/// session, each value written out so the demo reads the same every time.
enum DemoData {
    static func seed(into context: ModelContext) throws {
        let push = Routine(name: "Push day")
        push.exercises.append(PlannedExercise(name: "Bench press", section: .strength, sets: 3, reps: 8, weightKg: 60, order: 0))
        push.exercises.append(PlannedExercise(name: "Overhead press", section: .strength, sets: 3, reps: 8, weightKg: 40, order: 1))
        push.exercises.append(PlannedExercise(name: "Dips", section: .strength, sets: 3, reps: 10, weightKg: 0, order: 2))
        push.exercises.append(PlannedExercise(name: "Row 500 m", section: .cardio, sets: 1, reps: 1, weightKg: 0, order: 3))
        push.exercises.append(PlannedExercise(name: "Pec stretch", section: .stretching, sets: 1, reps: 1, weightKg: 0, order: 4))
        context.insert(push)

        let calendar = Calendar.current
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
        let session = Session(title: "Push day", scheduledFor: lastWeek)
        session.startedAt = lastWeek
        session.finishedAt = calendar.date(byAdding: .minute, value: 55, to: lastWeek)

        let bench = Entry(name: "Bench press", order: 0)
        bench.sets.append(LoggedSet(index: 0, reps: 8, weightKg: 60))
        bench.sets.append(LoggedSet(index: 1, reps: 8, weightKg: 60))
        bench.sets.append(LoggedSet(index: 2, reps: 7, weightKg: 60))
        bench.sets.forEach { $0.done = true }
        session.entries.append(bench)

        let press = Entry(name: "Overhead press", order: 1)
        press.sets.append(LoggedSet(index: 0, reps: 8, weightKg: 40))
        press.sets.append(LoggedSet(index: 1, reps: 6, weightKg: 40))
        press.sets.append(LoggedSet(index: 2, reps: 5, weightKg: 37.5))
        press.sets.forEach { $0.done = true }
        session.entries.append(press)

        let dips = Entry(name: "Dips", order: 2)
        dips.sets.append(LoggedSet(index: 0, reps: 10, weightKg: 0))
        dips.sets.append(LoggedSet(index: 1, reps: 10, weightKg: 0))
        dips.sets.append(LoggedSet(index: 2, reps: 8, weightKg: 0))
        dips.sets[0].done = true
        dips.sets[1].done = true
        session.entries.append(dips)

        context.insert(session)

        let today = Session(title: "Push day", scheduledFor: calendar.startOfDay(for: .now))
        for exercise in push.exercises.sorted(by: { $0.order < $1.order }) {
            let entry = Entry(name: exercise.name, order: exercise.order)
            for index in 0..<exercise.sets {
                entry.sets.append(LoggedSet(index: index, reps: exercise.reps, weightKg: exercise.weightKg))
            }
            today.entries.append(entry)
        }
        context.insert(today)

        try context.save()
    }
}
