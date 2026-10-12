import Foundation
import CoreLocation

public final class LocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<LocationData?, Never>?
    private var authContinuation: CheckedContinuation<Bool, Never>?

    public var isAuthorized: Bool {
        manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
    }

    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    public func requestAuthorization() async -> Bool {
        if isAuthorized { return true }
        guard manager.authorizationStatus == .notDetermined else { return false }
        
        return await withCheckedContinuation { continuation in
            self.authContinuation = continuation
            self.manager.requestWhenInUseAuthorization()
        }
    }

    public func getCurrentLocation() async -> LocationData? {
        guard isAuthorized else { return nil }

        return await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            self.manager.requestLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if let cont = authContinuation {
            cont.resume(returning: isAuthorized)
            authContinuation = nil
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else {
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
            return
        }
        let data = LocationData(
            latitude: loc.coordinate.latitude,
            longitude: loc.coordinate.longitude,
            accuracyMeters: loc.horizontalAccuracy,
            altitudeMeters: loc.altitude
        )
        locationContinuation?.resume(returning: data)
        locationContinuation = nil
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }
}
