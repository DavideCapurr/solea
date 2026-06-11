import Foundation

/// I traguardi sbloccabili. I `rawValue` sono stabili: usati anche come ID
/// degli achievement di Game Center.
public enum Badge: String, CaseIterable, Sendable, Identifiable {
    case firstSession
    case weekStreak
    case plannerCompleted
    case vitaminD10k

    public var id: String { rawValue }

    /// Titolo (in italiano, lingua sorgente / chiave di localizzazione).
    public var titleKey: String {
        switch self {
        case .firstSession: return "Prima sessione"
        case .weekStreak: return "7 giorni smart"
        case .plannerCompleted: return "Vacanza preparata"
        case .vitaminD10k: return "10.000 IU di vitamina D"
        }
    }

    public var detailKey: String {
        switch self {
        case .firstSession: return "Hai completato la tua prima sessione."
        case .weekStreak: return "Sette giorni di fila di esposizione intelligente."
        case .plannerCompleted: return "Hai completato un piano di preparazione vacanza."
        case .vitaminD10k: return "Hai accumulato 10.000 IU di vitamina D stimata."
        }
    }

    public var systemImage: String {
        switch self {
        case .firstSession: return "sun.max"
        case .weekStreak: return "flame"
        case .plannerCompleted: return "airplane"
        case .vitaminD10k: return "pills"
        }
    }
}

/// Stato necessario a valutare quali badge sono sbloccati.
public struct BadgeProgress: Sendable {
    public let sessionCount: Int
    public let currentStreak: Int
    public let completedPlans: Int
    public let totalVitaminDIU: Double

    public init(sessionCount: Int, currentStreak: Int, completedPlans: Int, totalVitaminDIU: Double) {
        self.sessionCount = sessionCount
        self.currentStreak = currentStreak
        self.completedPlans = completedPlans
        self.totalVitaminDIU = totalVitaminDIU
    }
}

public extension Badge {
    static let vitaminDThreshold = 10_000.0
    static let weekStreakDays = 7

    /// Insieme dei badge sbloccati dato lo stato corrente.
    static func unlocked(for progress: BadgeProgress) -> Set<Badge> {
        var result: Set<Badge> = []
        if progress.sessionCount >= 1 { result.insert(.firstSession) }
        if progress.currentStreak >= weekStreakDays { result.insert(.weekStreak) }
        if progress.completedPlans >= 1 { result.insert(.plannerCompleted) }
        if progress.totalVitaminDIU >= vitaminDThreshold { result.insert(.vitaminD10k) }
        return result
    }
}
