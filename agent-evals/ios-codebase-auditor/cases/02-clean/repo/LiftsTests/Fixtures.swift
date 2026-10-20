import Foundation
@testable import Lifts

/// One session with one entry and the given sets, in the shape every test uses.
func makeSession(title: String = "Push", exercise: String = "Bench", on date: Date, sets done: [Bool]) -> Session {
    let session = Session(title: title, scheduledFor: date)
    let entry = Entry(name: exercise, order: 0)
    for (index, isDone) in done.enumerated() {
        let set = LoggedSet(index: index, reps: 8, weightKg: 60)
        set.done = isDone
        set.entry = entry
        entry.sets.append(set)
    }
    entry.session = session
    session.entries.append(entry)
    return session
}
