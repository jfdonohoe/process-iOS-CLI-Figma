import CoreMotion

/// Detects chest movement from the accelerometer when the phone rests on the user.
final class BreathMotion {
    private let motion = CMMotionManager()

    func start(_ onSample: @escaping (Double) -> Void) {
        motion.accelerometerUpdateInterval = 1.0 / 30
        motion.startAccelerometerUpdates(to: .main) { data, _ in
            if let z = data?.acceleration.z { onSample(z) }
        }
    }
}
