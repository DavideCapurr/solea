import Foundation
import Observation
import SoleaCore

/// Tutti i valori mostrati dalla schermata Oggi, precalcolati in `load()` così
/// che ogni errore (posizione, WeatherKit, dati UV invalidi) emerga lì e venga
/// mostrato con retry — mai durante il render.
struct TodayMetrics {
    let conditions: UVConditions
    let burnRisk: BurnRisk
    let safeMinutesBareSkin: Double
    let safeMinutesSPF30: Double
    let goldenHours: [DateInterval]
}

@MainActor
@Observable
final class TodayViewModel {
    enum State {
        case loading
        case loaded(TodayMetrics)
        case failed(message: String)
    }

    private(set) var state: State = .loading

    private let locationService = LocationService()
    private let uvService = UVService()

    /// `doseToday`: dose UV effettiva già accumulata oggi (somma delle sessioni).
    func load(phototype: Fitzpatrick, doseToday: Double) async {
        state = .loading
        do {
            let location = try await locationService.currentLocation()
            let conditions = try await uvService.conditions(for: location)
            let metrics = TodayMetrics(
                conditions: conditions,
                burnRisk: BurnRisk.level(
                    doseTodayJoulesPerSquareMeter: doseToday,
                    phototype: phototype,
                    currentUVIndex: conditions.currentUVIndex
                ),
                safeMinutesBareSkin: try SafeExposure.minutes(
                    phototype: phototype,
                    uvIndex: conditions.currentUVIndex
                ),
                safeMinutesSPF30: try SafeExposure.minutes(
                    phototype: phototype,
                    uvIndex: conditions.currentUVIndex,
                    spf: 30
                ),
                goldenHours: GoldenHours.windows(in: conditions.hourly, phototype: phototype)
            )
            state = .loaded(metrics)
        } catch {
            // Errore propagato fino alla UI con messaggio e retry, mai nascosto.
            state = .failed(message: error.localizedDescription)
        }
    }
}
