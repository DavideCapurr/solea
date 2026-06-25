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
        static let goal = "session.goal"
        static let stop = "session.stop"
        static let hydration = "session.hydration"
        static let afterSun = "session.afterSun"
        static let all = [flip, reapply, goal, stop, hydration, afterSun]
        static let goldenHourApproachingPrefix = "goldenHour.approaching."
        static let goldenHourStartPrefix = "goldenHour.start."
        static let maximumGoldenHourWindows = 6
        static let goldenHourAll = (0..<maximumGoldenHourWindows).flatMap { index in
            [
                "\(goldenHourApproachingPrefix)\(index)",
                "\(goldenHourStartPrefix)\(index)"
            ]
        }
    }

    private let center = UNUserNotificationCenter.current()
    private static let goldenHourLeadTime: TimeInterval = 30 * 60

    /// Richiede l'autorizzazione. Ritorna `false` se l'utente la nega (scelta
    /// legittima, la UI lo segnala); lancia solo per errori reali del sistema.
    ///
    /// Usa notifiche locali standard: anche lo stop di sicurezza è un avviso
    /// normale. Non richiediamo l'entitlement Critical Alerts
    /// (`com.apple.developer.usernotifications.critical-alerts`), riservato da
    /// Apple ad app salvavita e non concesso a un'app di abbronzatura.
    func requestAuthorization() async throws -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            throw NotificationError.underlying(error)
        }
    }

    /// Autorizzazione standard per promemoria non critici, come le ore ideali.
    func requestStandardAuthorization() async throws -> Bool {
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
        try await scheduleReapplyReminder(afterSeconds: Double(minutes) * 60)
    }

    func scheduleReapplyReminder(afterSeconds seconds: Double) async throws {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.reapply])
        guard seconds.isFinite, seconds >= 1 else { return }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Riapplica la crema")
        content.body = String(localized: "Sono passate quasi due ore: rimetti la protezione solare.")
        content.sound = .default
        try await schedule(
            id: Identifier.reapply,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 1), repeats: false)
        )
    }

    /// Avviso quando la durata-obiettivo della sessione è stata raggiunta.
    func scheduleGoalReminder(afterSeconds seconds: Double) async throws {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.goal])
        guard seconds.isFinite, seconds >= 1 else { return }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Obiettivo raggiunto")
        content.body = String(localized: "Hai completato il tempo previsto: valuta ombra, doposole o una pausa.")
        content.sound = .default
        try await schedule(
            id: Identifier.goal,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 1), repeats: false)
        )
    }

    /// Programma (o riprogramma) l'avviso quando si esaurisce il limite prudente.
    func scheduleStopAlert(afterSeconds seconds: Double) async throws {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.stop])
        guard seconds.isFinite, seconds >= 1 else { return }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Limite prudente esaurito")
        content.body = String(localized: "Mettiti all'ombra o aggiorna la protezione prima di continuare.")
        // Suono standard: lo stop di sicurezza non usa Critical Alerts (entitlement
        // non richiesto), così evitiamo un gate Apple non necessario per l'app.
        content.sound = .default
        try await schedule(
            id: Identifier.stop,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 1), repeats: false)
        )
    }

    /// Promemoria idratazione ricorrente durante le sessioni lunghe.
    func scheduleHydrationReminder(everyMinutes minutes: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Bevi un po' d'acqua")
        content.body = String(localized: "Il sole disidrata: un sorso d'acqua aiuta pelle e abbronzatura.")
        content.sound = .default
        try await schedule(
            id: Identifier.hydration,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: Double(minutes) * 60, repeats: true)
        )
    }

    /// Promemoria doposole la sera, dopo una giornata di esposizione.
    func scheduleAfterSunReminder(at date: Date) async throws {
        guard date > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Doposole")
        content.body = String(localized: "Applica una crema doposole e idratati: la tua pelle ti ringrazierà.")
        content.sound = .default
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        try await schedule(
            id: Identifier.afterSun,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
    }

    /// Programma gli inviti ad aprire Solea prima e all'inizio delle prossime
    /// finestre ideali di abbronzatura.
    @discardableResult
    func scheduleGoldenHourReminders(
        for windows: [DateInterval],
        now: Date = .now,
        calendar: Calendar = .current
    ) async throws -> Int {
        center.removePendingNotificationRequests(withIdentifiers: Identifier.goldenHourAll)

        let upcomingWindows = windows
            .sorted { $0.start < $1.start }
            .filter { $0.end > now }
            .prefix(Identifier.maximumGoldenHourWindows)

        var scheduledCount = 0
        for (index, window) in upcomingWindows.enumerated() {
            let approachingDate = window.start.addingTimeInterval(-Self.goldenHourLeadTime)
            if approachingDate > now {
                try await scheduleGoldenHourReminder(
                    id: "\(Identifier.goldenHourApproachingPrefix)\(index)",
                    title: String(localized: "Tra poco sole ideale"),
                    body: String(localized: "La finestra migliore si avvicina. Apri Solea per controllare UV, SPF e durata prima di esporti."),
                    date: approachingDate,
                    calendar: calendar
                )
                scheduledCount += 1
            }

            if window.start > now {
                try await scheduleGoldenHourReminder(
                    id: "\(Identifier.goldenHourStartPrefix)\(index)",
                    title: String(localized: "È il momento giusto per abbronzarti"),
                    body: String(localized: "Le condizioni sono tra le più favorevoli per il tuo fototipo. Entra in Solea e avvia una sessione prudente."),
                    date: window.start,
                    calendar: calendar
                )
                scheduledCount += 1
            }
        }

        return scheduledCount
    }

    func cancelGoldenHourReminders() {
        center.removePendingNotificationRequests(withIdentifiers: Identifier.goldenHourAll)
        center.removeDeliveredNotifications(withIdentifiers: Identifier.goldenHourAll)
    }

    func cancelSessionReminders() {
        center.removePendingNotificationRequests(withIdentifiers: Identifier.all)
        center.removeDeliveredNotifications(withIdentifiers: Identifier.all)
    }

    func cancelExposureReminders() {
        center.removePendingNotificationRequests(withIdentifiers: [
            Identifier.flip,
            Identifier.reapply,
            Identifier.goal,
            Identifier.stop,
            Identifier.hydration
        ])
    }

    private func scheduleGoldenHourReminder(
        id: String,
        title: String,
        body: String,
        date: Date,
        calendar: Calendar
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.threadIdentifier = "goldenHour"
        content.userInfo = ["destination": "today"]
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        try await schedule(
            id: id,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
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
