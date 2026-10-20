import CoreLocation

@Observable
final class LocationTracker: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var latest: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        latest = locations.last
    }
}
