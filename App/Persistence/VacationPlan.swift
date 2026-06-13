import Foundation
import SwiftData

/// Un piano di preparazione all'abbronzatura per una vacanza, con i giorni
/// generati da `TanPlanner` serializzati per la persistenza.
@Model
final class VacationPlan {
    private(set) var destinationName: String
    private(set) var departureDate: Date
    private(set) var expectedUVIndex: Double
    private(set) var phototypeRawValue: Int
    private(set) var createdAt: Date
    /// Giorni del piano, ordinati, serializzati come JSON.
    private(set) var serializedDays: Data

    init(
        destinationName: String,
        departureDate: Date,
        expectedUVIndex: Double,
        phototypeRawValue: Int,
        days: [StoredPlanDay],
        createdAt: Date = .now
    ) throws {
        self.destinationName = destinationName
        self.departureDate = departureDate
        self.expectedUVIndex = expectedUVIndex
        self.phototypeRawValue = phototypeRawValue
        self.createdAt = createdAt
        self.serializedDays = try JSONEncoder().encode(days)
    }

    /// Decodifica i giorni; propaga l'errore invece di restituire un piano vuoto.
    func days() throws -> [StoredPlanDay] {
        try JSONDecoder().decode([StoredPlanDay].self, from: serializedDays)
    }
}

/// Rappresentazione persistente di un giorno del piano (specchio di `TanPlanDay`).
struct StoredPlanDay: Codable, Identifiable, Hashable {
    let id: Int
    let date: Date
    let minutes: Int
    let spf: Int
}
