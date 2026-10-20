import SwiftUI
import SwiftData

/// The next session to do: the earliest one not yet finished or abandoned,
/// whatever day it was planned for, so a missed session is never skipped.
struct TodayScreen: View {
    @Query(sort: \Session.scheduledFor) private var sessions: [Session]

    var body: some View {
        if let next = sessions.first(where: { !$0.isLocked }) {
            SessionScreen(session: next)
        } else {
            ContentUnavailableView("Nothing scheduled", systemImage: "calendar")
        }
    }
}
