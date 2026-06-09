import Foundation
import CoreLocation

enum LocationError: LocalizedError {
    case authorizationDenied
    case noLocation
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return String(localized: "Permesso di posizione negato. Abilitalo in Impostazioni > Privacy > Localizzazione per vedere l'UV della tua zona.")
        case .noLocation:
            return String(localized: "Posizione non disponibile. Riprova tra qualche istante.")
        case .underlying(let error):
            return String(localized: "Errore di localizzazione: \(error.localizedDescription)")
        }
    }
}

/// Wrapper async di CLLocationManager per richieste one-shot della posizione.
/// Gli errori non vengono mai assorbiti: arrivano tipizzati al chiamante.
@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentLocation() async throws -> CLLocation {
        var status = manager.authorizationStatus
        if status == .notDetermined {
            status = await requestAuthorization()
        }
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        default:
            throw LocationError.authorizationDenied
        }
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    private func requestAuthorization() async -> CLAuthorizationStatus {
        await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard status != .notDetermined, let continuation = self.authorizationContinuation else { return }
            self.authorizationContinuation = nil
            continuation.resume(returning: status)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        Task { @MainActor in
            guard let continuation = self.locationContinuation else { return }
            self.locationContinuation = nil
            if let location {
                continuation.resume(returning: location)
            } else {
                continuation.resume(throwing: LocationError.noLocation)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            guard let continuation = self.locationContinuation else { return }
            self.locationContinuation = nil
            continuation.resume(throwing: LocationError.underlying(error))
        }
    }
}
