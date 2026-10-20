import SwiftUI

struct GoalsView: View {
    @AppStorage("yearlyGoal") private var yearlyGoal = 24
    @State private var editing = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(yearlyGoal) books this year")
                    .font(.title2.bold())
                    .foregroundStyle(Color.ink)
                Text("Pick a number you can keep. You can change it at any time.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("Goals")
            .toolbar {
                Button {
                    editing = true
                } label: {
                    Image("goal-edit")
                }
            }
        }
    }
}
