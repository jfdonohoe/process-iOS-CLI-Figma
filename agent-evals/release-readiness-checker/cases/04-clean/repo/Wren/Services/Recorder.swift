import AVFoundation

final class Recorder {
    private var recorder: AVAudioRecorder?

    func start(to url: URL) async throws {
        guard await AVAudioApplication.requestRecordPermission() else { return }
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
        recorder = try AVAudioRecorder(url: url, settings: [AVFormatIDKey: kAudioFormatMPEG4AAC])
        recorder?.record()
    }

    func stop() { recorder?.stop() }
}
