import Foundation
import HealthKit

enum HealthKitError: LocalizedError {
    case notAvailable
    case writeDenied
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return String(localized: "Apple Health non è disponibile su questo dispositivo.")
        case .writeDenied:
            return String(localized: "Permesso di scrittura su Salute negato. Puoi abilitarlo in Salute > Profilo > App > Abbronzo.")
        case .underlying(let error):
            return String(localized: "Salvataggio su Salute non riuscito: \(error.localizedDescription)")
        }
    }
}

/// Scrive su Apple Health il tempo alla luce del giorno di una sessione conclusa.
final class HealthKitService {
    private let store = HKHealthStore()
    private let daylightType = HKQuantityType(.timeInDaylight)

    func saveSession(_ session: FinishedSession) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        do {
            try await store.requestAuthorization(
                toShare: [daylightType],
                read: []
            )
        } catch {
            throw HealthKitError.underlying(error)
        }

        guard store.authorizationStatus(for: daylightType) == .sharingAuthorized else {
            throw HealthKitError.writeDenied
        }

        let sample = HKQuantitySample(
            type: daylightType,
            quantity: HKQuantity(unit: .minute(), doubleValue: session.duration / 60),
            start: session.startedAt,
            end: session.endedAt
        )

        do {
            try await store.save(sample)
        } catch {
            throw HealthKitError.underlying(error)
        }
    }
}
