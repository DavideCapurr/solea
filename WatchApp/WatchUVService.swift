import Foundation
import CoreLocation
import WeatherKit
import SoleaCore

enum WatchUVError: LocalizedError {
    case authorizationDenied
    case noLocation
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return String(localized: "Permesso di posizione negato.")
        case .noLocation:
            return String(localized: "Posizione non disponibile.")
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}

struct WatchUV {
    let uvIndex: Double
}

/// Recupero posizione + UV per il polso. Stesso principio dell'app: gli errori
/// arrivano tipizzati alla UI, nessun valore di ripiego silenzioso.
@MainActor
final class WatchUVService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentUV() async throws -> WatchUV {
        let location = try await currentLocation()
        do {
            let current = try await WeatherService.shared.weather(for: location, including: .current)
            return WatchUV(uvIndex: Double(current.uvIndex.value))
        } catch {
            throw WatchUVError.underlying(error)
        }
    }

    private func currentLocation() async throws -> CLLocation {
        var status = manager.authorizationStatus
        if status == .notDetermined {
            status = await withCheckedContinuation { continuation in
                authContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        }
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            throw WatchUVError.authorizationDenied
        }
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard status != .notDetermined, let continuation = self.authContinuation else { return }
            self.authContinuation = nil
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
                continuation.resume(throwing: WatchUVError.noLocation)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            guard let continuation = self.locationContinuation else { return }
            self.locationContinuation = nil
            continuation.resume(throwing: WatchUVError.underlying(error))
        }
    }
}
