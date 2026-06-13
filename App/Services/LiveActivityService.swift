import Foundation
import ActivityKit
import SoleaCore

enum LiveActivityError: LocalizedError {
    case notEnabled
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .notEnabled:
            return String(localized: "Le Live Activity sono disattivate: abilitale in Impostazioni > Solea per vedere il timer nella Dynamic Island.")
        case .underlying(let error):
            return String(localized: "Avvio della Live Activity non riuscito: \(error.localizedDescription)")
        }
    }
}

/// Gestisce la Live Activity della sessione (lock screen + Dynamic Island).
@MainActor
final class LiveActivityService {
    private var activity: Activity<SessionActivityAttributes>?

    func start(
        phototype: Fitzpatrick,
        startedAt: Date,
        state: SessionActivityAttributes.ContentState
    ) throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw LiveActivityError.notEnabled
        }
        do {
            activity = try Activity.request(
                attributes: SessionActivityAttributes(
                    phototypeRoman: phototype.romanNumeral,
                    startedAt: startedAt
                ),
                content: .init(state: state, staleDate: nil)
            )
        } catch {
            throw LiveActivityError.underlying(error)
        }
    }

    func update(state: SessionActivityAttributes.ContentState) async {
        await activity?.update(.init(state: state, staleDate: nil))
    }

    func end(state: SessionActivityAttributes.ContentState) async {
        await activity?.end(
            .init(state: state, staleDate: nil),
            dismissalPolicy: .after(.now + 5 * 60)
        )
        activity = nil
    }
}
