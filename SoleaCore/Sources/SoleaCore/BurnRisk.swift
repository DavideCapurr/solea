import Foundation

/// Semaforo del rischio scottatura: combina la dose UV già accumulata oggi
/// (in frazione della MED del fototipo) con l'indice UV attuale.
public enum BurnRisk: String, CaseIterable, Sendable {
    case low
    case moderate
    case high

    public static func level(
        doseTodayJoulesPerSquareMeter dose: Double,
        phototype: Fitzpatrick,
        currentUVIndex uv: Double
    ) -> BurnRisk {
        let fractionOfMED = max(0, dose) / phototype.med
        if fractionOfMED >= SafeExposure.recommendedLimitFractionOfMED || uv >= 8 {
            return .high
        }
        if fractionOfMED >= 0.4 || uv >= 3 {
            return .moderate
        }
        return .low
    }
}
