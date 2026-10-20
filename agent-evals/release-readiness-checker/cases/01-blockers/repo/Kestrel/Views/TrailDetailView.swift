import SwiftUI

struct TrailDetailView: View {
    let hike: Hike
    @State private var showingCamera = false

    var body: some View {
        List {
            LabeledContent("Distance", value: hike.distanceMeters.formatted())
            Button("Add trail photo") { showingCamera = true }
        }
        .navigationTitle(hike.name)
        .sheet(isPresented: $showingCamera) { TrailPhotoCapture() }
    }
}
