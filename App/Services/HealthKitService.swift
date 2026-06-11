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
            return String(localized: "Permesso di scrittura su Salute negato. Puoi abilitarlo in Salute > Profilo > App > Solea.")
        case .underlying(let error):
            return String(localized: "Salvataggio su Salute non riuscito: \(error.localizedDescription)")
        }
    }
}

/// Scrive su Apple Health il tempo alla luce del giorno e la vitamina D stimata
/// di una sessione conclusa.
final class HealthKitService {
    private let store = HKHealthStore()
    private let daylightType = HKQuantityType(.timeInDaylight)
    private let vitaminDType = HKQuantityType(.dietaryVitaminD)

    func saveSession(_ session: FinishedSession) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        do {
            try await store.requestAuthorization(
                toShare: [daylightType, vitaminDType],
                read: []
            )
        } catch {
            throw HealthKitError.underlying(error)
        }

        guard store.authorizationStatus(for: daylightType) == .sharingAuthorized
                || store.authorizationStatus(for: vitaminDType) == .sharingAuthorized else {
            throw HealthKitError.writeDenied
        }

        var samples: [HKQuantitySample] = []
        if store.authorizationStatus(for: daylightType) == .sharingAuthorized {
            samples.append(HKQuantitySample(
                type: daylightType,
                quantity: HKQuantity(unit: .minute(), doubleValue: session.duration / 60),
                start: session.startedAt,
                end: session.endedAt
            ))
        }
        if session.vitaminDIU > 0,
           store.authorizationStatus(for: vitaminDType) == .sharingAuthorized {
            // Health registra la vitamina D in microgrammi: 1 µg = 40 IU.
            samples.append(HKQuantitySample(
                type: vitaminDType,
                quantity: HKQuantity(
                    unit: .gramUnit(with: .micro),
                    doubleValue: session.vitaminDIU / 40
                ),
                start: session.startedAt,
                end: session.endedAt
            ))
        }

        do {
            try await store.save(samples)
        } catch {
            throw HealthKitError.underlying(error)
        }
    }
}
