import Foundation
import GameKit
import SoleaCore

enum GameCenterError: LocalizedError {
    case notAuthenticated
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return String(localized: "Accedi a Game Center (Impostazioni > Game Center) per classifiche e obiettivi.")
        case .underlying(let error):
            return String(localized: "Errore Game Center: \(error.localizedDescription)")
        }
    }
}

/// Integrazione Game Center: classifiche (minuti smart settimanali, streak) e
/// achievement nativi mappati 1:1 sui `Badge` di SoleaCore.
@MainActor
final class GameCenterService {
    static let weeklySmartMinutesLeaderboard = "solea.weekly.smart.minutes"
    static let longestStreakLeaderboard = "solea.longest.streak"

    private(set) var isAuthenticated = false

    func authenticate() async {
        // GKLocalPlayer presenta da sé la UI di login quando serve; qui registriamo
        // solo l'esito. L'app resta pienamente utilizzabile anche da non autenticati.
        await withCheckedContinuation { continuation in
            GKLocalPlayer.local.authenticateHandler = { _, _ in
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                continuation.resume()
            }
        }
    }

    func submitWeeklySmartMinutes(_ minutes: Int) async throws {
        try await submit(minutes, to: Self.weeklySmartMinutesLeaderboard)
    }

    func submitLongestStreak(_ days: Int) async throws {
        try await submit(days, to: Self.longestStreakLeaderboard)
    }

    private func submit(_ value: Int, to leaderboardID: String) async throws {
        guard GKLocalPlayer.local.isAuthenticated else { throw GameCenterError.notAuthenticated }
        do {
            try await GKLeaderboard.submitScore(
                value,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardID]
            )
        } catch {
            throw GameCenterError.underlying(error)
        }
    }

    /// Riporta i badge sbloccati come achievement Game Center (100% completati).
    func report(unlocked: Set<Badge>) async throws {
        guard GKLocalPlayer.local.isAuthenticated else { throw GameCenterError.notAuthenticated }
        let achievements = unlocked.map { badge -> GKAchievement in
            let achievement = GKAchievement(identifier: badge.rawValue)
            achievement.percentComplete = 100
            achievement.showsCompletionBanner = true
            return achievement
        }
        guard !achievements.isEmpty else { return }
        do {
            try await GKAchievement.report(achievements)
        } catch {
            throw GameCenterError.underlying(error)
        }
    }
}
