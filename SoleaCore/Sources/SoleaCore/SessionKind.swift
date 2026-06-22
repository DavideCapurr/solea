import Foundation

/// Tipo di sessione: sole all'aperto o lettino/solarium indoor.
public enum SessionKind: String, Codable, Sendable, CaseIterable {
    case sun
    case solarium
}

/// Conversione della potenza di un lettino solare in un indice UV equivalente,
/// così che il calcolo di dose ed esposizione prudente sia lo stesso del sole.
///
/// I lettori commerciali si classificano in tipi 1–4 per irradianza UV totale;
/// usiamo un UV-equivalente indicativo per ciascun livello. Resta una stima.
public enum SolariumPower: Int, Codable, Sendable, CaseIterable, Identifiable {
    case low = 1
    case medium = 2
    case high = 3
    case veryHigh = 4

    public var id: Int { rawValue }

    /// Indice UV equivalente del lettino a questo livello di potenza.
    public var equivalentUVIndex: Double {
        switch self {
        case .low: return 6
        case .medium: return 9
        case .high: return 12
        case .veryHigh: return 15
        }
    }
}
