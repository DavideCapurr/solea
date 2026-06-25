import Foundation
import GameKit
import SoleaCore
import UIKit

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
        // L'app resta pienamente utilizzabile anche da non autenticati.
        await withCheckedContinuation { continuation in
            let authContinuation = GameCenterAuthContinuation()
            GKLocalPlayer.local.authenticateHandler = { viewController, _ in
                Task { @MainActor in
                    if let viewController, Self.present(viewController) {
                        return
                    }
                    self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                    authContinuation.resume(continuation)
                }
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

    private static func present(_ viewController: UIViewController) -> Bool {
        guard let presenter = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController else {
            return false
        }

        var topPresenter = presenter
        while let presented = topPresenter.presentedViewController {
            topPresenter = presented
        }
        topPresenter.present(viewController, animated: true)
        return true
    }
}

private final class GameCenterAuthContinuation {
    private var didResume = false

    func resume(_ continuation: CheckedContinuation<Void, Never>) {
        guard !didResume else { return }
        didResume = true
        continuation.resume()
    }
}
