import Foundation
import CoreLocation
import WeatherKit
import SoleaCore

struct UVConditions {
    let currentUVIndex: Double
    /// Previsione oraria dall'ora corrente alle prossime 24 ore.
    let hourly: [UVHour]
    let fetchedAt: Date
}

enum UVServiceError: LocalizedError {
    case weatherKit(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .weatherKit(let error):
            return String(localized: "Impossibile recuperare i dati UV: \(error.localizedDescription)")
        }
    }
}

/// Recupera l'indice UV attuale e la previsione oraria da WeatherKit.
final class UVService {
    func conditions(for location: CLLocation) async throws -> UVConditions {
        let current: CurrentWeather
        let hourlyForecast: Forecast<HourWeather>
        do {
            (current, hourlyForecast) = try await WeatherService.shared.weather(
                for: location,
                including: .current, .hourly
            )
        } catch {
            throw UVServiceError.weatherKit(underlying: error)
        }

        let now = Date.now
        let windowEnd = now.addingTimeInterval(24 * 3600)
        let hourly = hourlyForecast.forecast
            .filter { $0.date >= now.addingTimeInterval(-3600) && $0.date <= windowEnd }
            .map { UVHour(date: $0.date, uvIndex: Double($0.uvIndex.value)) }

        return UVConditions(
            currentUVIndex: Double(current.uvIndex.value),
            hourly: hourly,
            fetchedAt: now
        )
    }
}
