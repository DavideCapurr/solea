import Foundation

/// Fototipo cutaneo secondo la scala di Fitzpatrick (I–VI).
public enum Fitzpatrick: Int, CaseIterable, Codable, Sendable, Identifiable {
    case typeI = 1
    case typeII = 2
    case typeIII = 3
    case typeIV = 4
    case typeV = 5
    case typeVI = 6

    public var id: Int { rawValue }

    /// Minimal Erythema Dose in J/m² (pesatura eritemale CIE): la dose UV
    /// oltre la quale compare l'eritema per questo fototipo.
    public var med: Double {
        switch self {
        case .typeI: return 200
        case .typeII: return 250
        case .typeIII: return 300
        case .typeIV: return 450
        case .typeV: return 600
        case .typeVI: return 1000
        }
    }

    public var romanNumeral: String {
        switch self {
        case .typeI: return "I"
        case .typeII: return "II"
        case .typeIII: return "III"
        case .typeIV: return "IV"
        case .typeV: return "V"
        case .typeVI: return "VI"
        }
    }

    /// Chiave di localizzazione (in italiano, lingua sorgente) della descrizione breve.
    public var summaryKey: String {
        switch self {
        case .typeI: return "Pelle molto chiara: si scotta sempre, non si abbronza."
        case .typeII: return "Pelle chiara: si scotta facilmente, si abbronza poco."
        case .typeIII: return "Pelle intermedia: a volte si scotta, si abbronza gradualmente."
        case .typeIV: return "Pelle olivastra: si scotta raramente, si abbronza bene."
        case .typeV: return "Pelle scura: si scotta molto raramente, si abbronza intensamente."
        case .typeVI: return "Pelle molto scura: non si scotta quasi mai."
        }
    }
}
