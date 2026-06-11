import Foundation
import Observation
import SoleaCore

struct SessionConfiguration {
    var spf: Double
    var zones: ExposedZones
    var flipIntervalMinutes: Int
    var kind: SessionKind = .sun
}

/// Dati di una sessione conclusa, pronti per essere persistiti e riepilogati.
struct FinishedSession {
    let startedAt: Date
    let endedAt: Date
    let configuration: SessionConfiguration
    let phototype: Fitzpatrick
    let averageUVIndex: Double
    /// Dose eritemale effettiva sulla pelle (J/m², attenuata dall'SPF).
    let effectiveDose: Double
    let vitaminDIU: Double

    var duration: TimeInterval { endedAt.timeIntervalSince(startedAt) }
    var fractionOfMED: Double { effectiveDose / phototype.med }
}

extension FinishedSession: Identifiable {
    var id: Date { startedAt }
}

/// Stato e ciclo di vita della sessione di abbronzatura attiva: integra la dose
/// UV secondo per secondo, aggiorna l'UV ogni 10 minuti e gestisce i promemoria.
@MainActor
@Observable
final class SessionManager {
    struct ActiveSession {
        let startedAt: Date
        let configuration: SessionConfiguration
        let phototype: Fitzpatrick
        var currentUVIndex: Double
        var effectiveDose: Double
        var uvSamples: [Double]
        var elapsedSeconds: Int
        var remindersEnabled: Bool
    }

    private(set) var active: ActiveSession?
    /// Avvisi non bloccanti, sempre visibili in UI: la sessione continua con
    /// l'ultimo dato valido ma l'utente sa che qualcosa non va.
    private(set) var uvRefreshWarning: String?
    private(set) var reminderWarning: String?
    private(set) var liveActivityWarning: String?

    private let notificationService = NotificationService()
    private let locationService = LocationService()
    private let uvService = UVService()
    private let liveActivityService = LiveActivityService()
    private var tickTask: Task<Void, Never>?
    private var uvRefreshTask: Task<Void, Never>?

    private static let uvRefreshIntervalSeconds: Double = 600
    private static let reapplyIntervalMinutes = 120
    private static let hydrationIntervalMinutes = 45
    /// La Live Activity viene aggiornata una volta ogni N tick (secondi).
    private static let liveActivityUpdateInterval = 30

    /// Orario del promemoria doposole (le 20:00 di oggi), se non è già passato.
    private static func afterSunTime(calendar: Calendar = .current) -> Date? {
        calendar.date(bySettingHour: 20, minute: 0, second: 0, of: .now)
    }

    var remainingSafeSeconds: Double? {
        guard let session = active else { return nil }
        let remainingDose = session.phototype.med - session.effectiveDose
        guard remainingDose > 0 else { return 0 }
        guard session.currentUVIndex > SafeExposure.negligibleUVIndex else { return .infinity }
        let dosePerSecond = session.currentUVIndex * SafeExposure.wattsPerUVIndexUnit
            / session.configuration.spf
        return remainingDose / dosePerSecond
    }

    func start(
        configuration: SessionConfiguration,
        phototype: Fitzpatrick,
        initialUVIndex: Double
    ) async {
        guard active == nil else { return }
        uvRefreshWarning = nil
        reminderWarning = nil
        liveActivityWarning = nil
        active = ActiveSession(
            startedAt: .now,
            configuration: configuration,
            phototype: phototype,
            currentUVIndex: initialUVIndex,
            effectiveDose: 0,
            uvSamples: [initialUVIndex],
            elapsedSeconds: 0,
            remindersEnabled: false
        )
        await scheduleReminders()
        startLiveActivity()
        startTicking()
        startUVRefreshLoop()
    }

    private func startLiveActivity() {
        guard let session = active, let state = activityState() else { return }
        do {
            try liveActivityService.start(
                phototype: session.phototype,
                startedAt: session.startedAt,
                state: state
            )
        } catch {
            // La sessione funziona anche senza Live Activity, ma l'utente lo sa.
            liveActivityWarning = error.localizedDescription
        }
    }

    /// Stato corrente per la Live Activity; `nil` se non c'è sessione attiva.
    private func activityState() -> SessionActivityAttributes.ContentState? {
        guard let session = active else { return nil }
        let remaining = remainingSafeSeconds
        return SessionActivityAttributes.ContentState(
            elapsedSeconds: session.elapsedSeconds,
            doseFraction: session.effectiveDose / session.phototype.med,
            currentUVIndex: session.currentUVIndex,
            remainingSafeSeconds: (remaining?.isFinite == true) ? remaining : nil
        )
    }

    func end() -> FinishedSession? {
        guard let session = active else { return nil }
        tickTask?.cancel()
        tickTask = nil
        uvRefreshTask?.cancel()
        uvRefreshTask = nil
        notificationService.cancelSessionReminders()
        let finalState = activityState()
        active = nil
        if let finalState {
            Task { await liveActivityService.end(state: finalState) }
        }

        let averageUV = session.uvSamples.reduce(0, +) / Double(session.uvSamples.count)
        return FinishedSession(
            startedAt: session.startedAt,
            endedAt: .now,
            configuration: session.configuration,
            phototype: session.phototype,
            averageUVIndex: averageUV,
            effectiveDose: session.effectiveDose,
            vitaminDIU: VitaminD.estimatedIU(
                effectiveDoseJoulesPerSquareMeter: session.effectiveDose,
                phototype: session.phototype,
                zones: session.configuration.zones
            )
        )
    }

    // MARK: - Promemoria

    private func scheduleReminders() async {
        guard let session = active else { return }
        do {
            let granted = try await notificationService.requestAuthorization()
            guard granted else {
                reminderWarning = String(localized: "Notifiche disattivate: non riceverai i promemoria. Abilitale in Impostazioni > Notifiche.")
                return
            }
            try await notificationService.scheduleFlipReminder(
                everyMinutes: session.configuration.flipIntervalMinutes
            )
            try await notificationService.scheduleReapplyReminder(
                everyMinutes: Self.reapplyIntervalMinutes
            )
            try await notificationService.scheduleHydrationReminder(
                everyMinutes: Self.hydrationIntervalMinutes
            )
            // Doposole la sera: solo per le sessioni al sole, non per il lettino.
            if session.configuration.kind == .sun,
               let afterSun = Self.afterSunTime() {
                try await notificationService.scheduleAfterSunReminder(at: afterSun)
            }
            if let remaining = remainingSafeSeconds, remaining.isFinite {
                try await notificationService.scheduleStopAlert(afterSeconds: remaining)
            }
            active?.remindersEnabled = true
        } catch {
            reminderWarning = error.localizedDescription
        }
    }

    // MARK: - Tick (1 s) e refresh UV (10 min)

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while true {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return // cancellazione del task: la sessione è terminata
                }
                guard let self, var session = self.active else { return }
                session.elapsedSeconds += 1
                session.effectiveDose += session.currentUVIndex
                    * SafeExposure.wattsPerUVIndexUnit
                    / session.configuration.spf
                self.active = session

                if session.elapsedSeconds % Self.liveActivityUpdateInterval == 0,
                   let state = self.activityState() {
                    await self.liveActivityService.update(state: state)
                }
            }
        }
    }

    private func startUVRefreshLoop() {
        // Il lettino ha un UV-equivalente fisso dato dalla potenza delle lampade:
        // non c'è nulla da aggiornare da WeatherKit.
        guard active?.configuration.kind == .sun else { return }
        uvRefreshTask?.cancel()
        uvRefreshTask = Task { [weak self] in
            while true {
                do {
                    try await Task.sleep(for: .seconds(Self.uvRefreshIntervalSeconds))
                } catch {
                    return
                }
                guard let self, self.active != nil else { return }
                await self.refreshUV()
            }
        }
    }

    private func refreshUV() async {
        do {
            let location = try await locationService.currentLocation()
            let conditions = try await uvService.conditions(for: location)
            guard var session = active else { return }
            session.currentUVIndex = conditions.currentUVIndex
            session.uvSamples.append(conditions.currentUVIndex)
            let remindersEnabled = session.remindersEnabled
            active = session
            uvRefreshWarning = nil

            if let state = activityState() {
                await liveActivityService.update(state: state)
            }

            // L'UV è cambiato: il momento dello stop di sicurezza va ricalcolato.
            if remindersEnabled, let remaining = remainingSafeSeconds, remaining.isFinite {
                do {
                    try await notificationService.scheduleStopAlert(afterSeconds: remaining)
                } catch {
                    reminderWarning = error.localizedDescription
                }
            }
        } catch {
            // La sessione continua con l'ultimo UV noto, ma l'avviso resta
            // visibile finché un refresh non riesce.
            uvRefreshWarning = error.localizedDescription
        }
    }
}
