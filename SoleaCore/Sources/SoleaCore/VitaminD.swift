import Foundation

/// Stima euristica della vitamina D sintetizzata durante l'esposizione.
///
/// Riferimento: una MED a corpo intero produce ~10.000–25.000 IU; usiamo un
/// valore prudente di 15.000 IU, scalato per superficie esposta ed efficienza
/// di sintesi del fototipo (la pelle più scura sintetizza più lentamente).
/// È una stima informativa, non un dato clinico.
public enum VitaminD {
    /// IU prodotte da una MED ricevuta a corpo intero (valore prudente).
    public static let iuPerFullBodyMED = 15_000.0

    /// Oltre questa soglia la sintesi giornaliera satura.
    public static let dailySaturationIU = 20_000.0

    public static func estimatedIU(
        effectiveDoseJoulesPerSquareMeter dose: Double,
        phototype: Fitzpatrick,
        zones: ExposedZones
    ) -> Double {
        guard dose > 0 else { return 0 }
        let iu = dose / phototype.med
            * iuPerFullBodyMED
            * zones.bodyFraction
            * synthesisEfficiency(for: phototype)
        return min(iu, dailySaturationIU)
    }

    /// Efficienza relativa di sintesi rispetto al fototipo I.
    static func synthesisEfficiency(for phototype: Fitzpatrick) -> Double {
        switch phototype {
        case .typeI: return 1.0
        case .typeII: return 1.0
        case .typeIII: return 0.9
        case .typeIV: return 0.7
        case .typeV: return 0.5
        case .typeVI: return 0.3
        }
    }
}
