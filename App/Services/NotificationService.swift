import Foundation
import UserNotifications

enum NotificationError: LocalizedError {
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .underlying(let error):
            return String(localized: "Errore nella programmazione dei promemoria: \(error.localizedDescription)")
        }
    }
}

/// Promemoria locali della sessione: "girati", "riapplica la crema", stop di sicurezza.
final class NotificationService {
    private enum Identifier {
        static let flip = "session.flip"
        static let reapply = "session.reapply"
        static let stop = "session.stop"
        static let all = [flip, reapply, stop]
    }

    private let center = UNUserNotificationCenter.current()

    /// Richiede l'autorizzazione. Ritorna `false` se l'utente la nega (scelta
    /// legittima, la UI lo segnala); lancia solo per errori reali del sistema.
    func requestAuthorization() async throws -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            throw NotificationError.underlying(error)
        }
    }

    func scheduleFlipReminder(everyMinutes minutes: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Girati!")
        content.body = String(localized: "È il momento di cambiare lato per un'abbronzatura uniforme.")
        content.sound = .default
        try await schedule(
            id: Identifier.flip,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: Double(minutes) * 60, repeats: true)
        )
    }

    func scheduleReapplyReminder(everyMinutes minutes: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Riapplica la crema")
        content.body = String(localized: "Sono passate quasi due ore: rimetti la protezione solare.")
        content.sound = .default
        try await schedule(
            id: Identifier.reapply,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: Double(minutes) * 60, repeats: true)
        )
    }

    /// Programma (o riprogramma) l'avviso di stop quando si esaurirà il tempo sicuro.
    func scheduleStopAlert(afterSeconds seconds: Double) async throws {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.stop])
        guard seconds.isFinite, seconds >= 1 else { return }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Tempo sicuro esaurito")
        content.body = String(localized: "Hai raggiunto la dose massima per la tua pelle: mettiti all'ombra.")
        content.sound = .defaultCritical
        try await schedule(
            id: Identifier.stop,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 1), repeats: false)
        )
    }

    func cancelSessionReminders() {
        center.removePendingNotificationRequests(withIdentifiers: Identifier.all)
        center.removeDeliveredNotifications(withIdentifiers: Identifier.all)
    }

    private func schedule(
        id: String,
        content: UNMutableNotificationContent,
        trigger: UNNotificationTrigger
    ) async throws {
        do {
            try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        } catch {
            throw NotificationError.underlying(error)
        }
    }
}
