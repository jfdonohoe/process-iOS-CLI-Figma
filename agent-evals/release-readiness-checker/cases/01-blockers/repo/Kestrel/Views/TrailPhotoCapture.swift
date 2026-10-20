import AVFoundation
import SwiftUI

struct TrailPhotoCapture: View {
    @State private var session = AVCaptureSession()
    @State private var denied = false

    var body: some View {
        Group {
            if denied {
                ContentUnavailableView("Camera off", systemImage: "camera.fill",
                                       description: Text("Turn on camera access in Settings to add trail photos."))
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .task { await start() }
    }

    private func start() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        guard granted, let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            denied = true
            return
        }
        session.addInput(input)
        session.startRunning()
    }
}
