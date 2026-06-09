import Foundation
import Observation
import SoleaCore

struct SessionConfiguration {
    var spf: Double
    var zones: ExposedZones
    var flipIntervalMinutes: Int
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

    private let notificationService = NotificationService()
    private let locationService = LocationService()
    private let uvService = UVService()
    private var tickTask: Task<Void, Never>?
    private var uvRefreshTask: Task<Void, Never>?

    private static let uvRefreshIntervalSeconds: Double = 600
    private static let reapplyIntervalMinutes = 120

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
        startTicking()
        startUVRefreshLoop()
    }

    func end() -> FinishedSession? {
        guard let session = active else { return nil }
        tickTask?.cancel()
        tickTask = nil
        uvRefreshTask?.cancel()
        uvRefreshTask = nil
        notificationService.cancelSessionReminders()
        active = nil

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
            }
        }
    }

    private func startUVRefreshLoop() {
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
