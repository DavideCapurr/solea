import Foundation
import CoreLocation
import WeatherKit

struct DestinationUV {
    let resolvedName: String
    let location: CLLocation
    /// UV massimo medio atteso (media dei picchi giornalieri disponibili).
    let expectedPeakUVIndex: Double
}

enum DestinationUVError: LocalizedError {
    case notFound(String)
    case noForecast
    case geocoding(Error)
    case weatherKit(Error)

    var errorDescription: String? {
        switch self {
        case .notFound(let query):
            return String(localized: "Nessuna località trovata per «\(query)». Controlla il nome e riprova.")
        case .noForecast:
            return String(localized: "Previsioni UV non disponibili per questa località.")
        case .geocoding(let error):
            return String(localized: "Errore nella ricerca della località: \(error.localizedDescription)")
        case .weatherKit(let error):
            return String(localized: "Impossibile recuperare le previsioni UV: \(error.localizedDescription)")
        }
    }
}

/// Risolve un nome di località in coordinate e ne stima l'UV di picco atteso,
/// usato dal tan planner per dimensionare l'esposizione graduale.
final class DestinationUVService {
    func expectedUV(forPlaceNamed query: String) async throws -> DestinationUV {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let placemarks: [CLPlacemark]
        do {
            placemarks = try await CLGeocoder().geocodeAddressString(trimmed)
        } catch {
            throw DestinationUVError.geocoding(error)
        }
        guard let placemark = placemarks.first, let location = placemark.location else {
            throw DestinationUVError.notFound(trimmed)
        }

        let daily: Forecast<DayWeather>
        do {
            daily = try await WeatherService.shared.weather(for: location, including: .daily)
        } catch {
            throw DestinationUVError.weatherKit(error)
        }

        let peaks = daily.forecast.map { Double($0.uvIndex.value) }
        guard !peaks.isEmpty else { throw DestinationUVError.noForecast }
        let averagePeak = peaks.reduce(0, +) / Double(peaks.count)

        return DestinationUV(
            resolvedName: resolvedName(from: placemark, fallback: trimmed),
            location: location,
            expectedPeakUVIndex: averagePeak
        )
    }

    private func resolvedName(from placemark: CLPlacemark, fallback: String) -> String {
        [placemark.locality, placemark.country]
            .compactMap { $0 }
            .joined(separator: ", ")
            .ifEmpty(fallback)
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
