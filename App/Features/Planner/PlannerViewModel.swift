import Foundation
import Observation
import SoleaCore

@MainActor
@Observable
final class PlannerViewModel {
    enum GenerationState: Equatable {
        case idle
        case loading
        case failed(String)
    }

    var destinationQuery = ""
    var departureDate = Calendar.current.date(byAdding: .day, value: 14, to: .now) ?? .now
    private(set) var generationState: GenerationState = .idle

    private let destinationService = DestinationUVService()

    /// Giorni disponibili da oggi alla partenza (estremi inclusi → escluso il giorno di partenza).
    func preparationDays(calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: .now)
        let departure = calendar.startOfDay(for: departureDate)
        let days = calendar.dateComponents([.day], from: today, to: departure).day ?? 0
        return max(0, days)
    }

    var canGenerate: Bool {
        !destinationQuery.trimmingCharacters(in: .whitespaces).isEmpty
            && TanPlanner.preparationDaysRange.contains(preparationDays())
            && generationState != .loading
    }

    /// Genera il piano e lo restituisce al chiamante per la persistenza.
    /// Ritorna `nil` in caso di errore (mostrato in `generationState`).
    func generate(phototype: Fitzpatrick) async -> (DestinationUV, [TanPlanDay])? {
        generationState = .loading
        do {
            let destination = try await destinationService.expectedUV(forPlaceNamed: destinationQuery)
            let plan = try TanPlanner.plan(
                phototype: phototype,
                preparationDays: preparationDays(),
                expectedUVIndex: clampedUV(destination.expectedPeakUVIndex),
                startingFrom: .now
            )
            generationState = .idle
            return (destination, plan)
        } catch {
            generationState = .failed(error.localizedDescription)
            return nil
        }
    }

    /// WeatherKit può restituire un UV di picco fuori dal range del planner
    /// (es. 0 in inverno): lo riportiamo nel dominio valido invece di fallire.
    private func clampedUV(_ uv: Double) -> Double {
        min(max(uv, TanPlanner.uvIndexRange.lowerBound), TanPlanner.uvIndexRange.upperBound)
    }
}
