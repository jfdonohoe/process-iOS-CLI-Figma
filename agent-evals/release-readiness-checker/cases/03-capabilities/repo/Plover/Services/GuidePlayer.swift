import AVFoundation

final class GuidePlayer {
    private var player: AVAudioPlayer?

    func play(_ url: URL) throws {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try AVAudioSession.sharedInstance().setActive(true)
        player = try AVAudioPlayer(contentsOf: url)
        player?.play()
    }
}
