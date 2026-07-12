import Foundation
import Observation
import SoleaCore

struct SessionConfiguration {
    var spf: Double
    var zones: ExposedZones
    var flipIntervalMinutes: Int
    var kind: SessionKind = .sun
    var goal: SunExposureGoal = .gradualTan
    var plannedDurationMinutes: Int = 20
    var advancedRemindersEnabled = false
    var advancedCompanionsEnabled = false
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
    let frontExposureSeconds: Int
    let backExposureSeconds: Int
    let plannedDurationMinutes: Int
    let exposureSeconds: Int
    let pausedSeconds: Int

    var duration: TimeInterval { TimeInterval(exposureSeconds) }
    var totalDuration: TimeInterval { endedAt.timeIntervalSince(startedAt) }
    var fractionOfMED: Double { effectiveDose / phototype.med }
    var goal: SunExposureGoal { configuration.goal }
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
        var sunscreenAppliedAtElapsedSeconds: Int?
        var lastHydrationAtElapsedSeconds: Int
        var currentSide: ExposureSide
        var frontExposureSeconds: Int
        var backExposureSeconds: Int
        var pausedSeconds: Int
        var isPaused: Bool
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
    private static let reapplyIntervalSeconds = reapplyIntervalMinutes * 60
    private static let hydrationIntervalMinutes = 45
    /// La Live Activity viene aggiornata una volta ogni N tick (secondi).
    private static let liveActivityUpdateInterval = 30

    /// Orario del promemoria doposole (le 20:00 di oggi), se non è già passato.
    private static func afterSunTime(calendar: Calendar = .current) -> Date? {
        calendar.date(bySettingHour: 20, minute: 0, second: 0, of: .now)
    }

    var remainingSafeSeconds: Double? {
        guard let session = active else { return nil }
        guard !session.isPaused else { return nil }
        let remainingDose = SafeExposure.recommendedDoseLimit(phototype: session.phototype)
            - session.effectiveDose
        guard remainingDose > 0 else { return 0 }
        guard session.currentUVIndex > SafeExposure.negligibleUVIndex else { return .infinity }
        let dosePerSecond = session.currentUVIndex * SafeExposure.wattsPerUVIndexUnit
            / currentSPFFactor(for: session)
        let doseLimitedSeconds = remainingDose / dosePerSecond
        if let secondsUntilReapplication = secondsUntilSunscreenReapplication(for: session) {
            return max(0, min(doseLimitedSeconds, secondsUntilReapplication))
        }
        return doseLimitedSeconds
    }

    var sunscreenNeedsReapplication: Bool {
        guard let session = active,
              session.configuration.spf > 1,
              let seconds = secondsUntilSunscreenReapplication(for: session)
        else {
            return false
        }
        return seconds <= 0
    }

    var nextFlipSeconds: Int? {
        guard let session = active else { return nil }
        guard !session.isPaused else { return nil }
        let interval = session.configuration.flipIntervalMinutes * 60
        guard interval > 0 else { return nil }
        let elapsedInInterval = session.elapsedSeconds % interval
        return elapsedInInterval == 0 ? interval : interval - elapsedInInterval
    }

    var nextHydrationSeconds: Int? {
        guard let session = active else { return nil }
        guard !session.isPaused else { return nil }
        let interval = Self.hydrationIntervalMinutes * 60
        let sinceLast = max(0, session.elapsedSeconds - session.lastHydrationAtElapsedSeconds)
        let elapsedInInterval = sinceLast % interval
        return elapsedInInterval == 0 ? interval : interval - elapsedInInterval
    }

    var nextSunscreenReapplicationSeconds: Int? {
        guard let session = active,
              !session.isPaused,
              let seconds = secondsUntilSunscreenReapplication(for: session)
        else {
            return nil
        }
        return Int(max(0, seconds.rounded()))
    }

    var goalRemainingSeconds: Int? {
        guard let session = active else { return nil }
        guard !session.isPaused else { return nil }
        let plannedSeconds = max(0, session.configuration.plannedDurationMinutes * 60)
        return max(0, plannedSeconds - session.elapsedSeconds)
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
            remindersEnabled: false,
            sunscreenAppliedAtElapsedSeconds: configuration.spf > 1 ? 0 : nil,
            lastHydrationAtElapsedSeconds: 0,
            currentSide: .front,
            frontExposureSeconds: 0,
            backExposureSeconds: 0,
            pausedSeconds: 0,
            isPaused: false
        )
        await scheduleReminders()
        startLiveActivity()
        startTicking()
        startUVRefreshLoop()
    }

    private func startLiveActivity() {
        guard let session = active, let state = activityState() else { return }
        guard session.configuration.advancedCompanionsEnabled else { return }
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

    func reapplySunscreen() async {
        // Disponibile anche senza Tanora Plus (usato dalla Modalità spiaggia):
        // resetta il timestamp di applicazione per la matematica della dose; la
        // schedulazione notifiche resta protetta da `remindersEnabled` più sotto.
        guard var session = active,
              session.configuration.spf > 1
        else {
            return
        }
        session.sunscreenAppliedAtElapsedSeconds = session.elapsedSeconds
        let remindersEnabled = session.remindersEnabled
        active = session

        guard remindersEnabled else { return }
        do {
            try await notificationService.scheduleReapplyReminder(
                everyMinutes: Self.reapplyIntervalMinutes
            )
            if let remaining = remainingSafeSeconds, remaining.isFinite {
                try await notificationService.scheduleStopAlert(afterSeconds: remaining)
            }
            reminderWarning = nil
        } catch {
            reminderWarning = error.localizedDescription
        }
    }

    func setExposureSide(_ side: ExposureSide) {
        guard var session = active else { return }
        session.currentSide = side
        active = session
    }

    /// Registra un sorso d'acqua: resetta il countdown idratazione in-app
    /// (mostrato dalla Modalità spiaggia) e, per le sessioni con promemoria
    /// avanzati attivi, riallinea la notifica ripetuta.
    func logHydration() async {
        guard var session = active else { return }
        session.lastHydrationAtElapsedSeconds = session.elapsedSeconds
        active = session

        guard session.remindersEnabled,
              session.configuration.advancedRemindersEnabled
        else {
            return
        }
        do {
            try await notificationService.scheduleHydrationReminder(
                everyMinutes: Self.hydrationIntervalMinutes
            )
            reminderWarning = nil
        } catch {
            reminderWarning = error.localizedDescription
        }
    }

    func pause() {
        guard var session = active, !session.isPaused else { return }
        session.isPaused = true
        active = session
        notificationService.cancelExposureReminders()
    }

    func resume() async {
        guard var session = active, session.isPaused else { return }
        session.isPaused = false
        let remindersEnabled = session.remindersEnabled
        active = session
        guard remindersEnabled else { return }
        await scheduleReminders(requestAuthorization: false)
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
            ),
            frontExposureSeconds: session.frontExposureSeconds,
            backExposureSeconds: session.backExposureSeconds,
            plannedDurationMinutes: session.configuration.plannedDurationMinutes,
            exposureSeconds: session.elapsedSeconds,
            pausedSeconds: session.pausedSeconds
        )
    }

    // MARK: - Promemoria

    private func scheduleReminders() async {
        await scheduleReminders(requestAuthorization: true)
    }

    private func scheduleReminders(requestAuthorization: Bool) async {
        guard let session = active else { return }
        guard !session.isPaused else { return }
        do {
            if requestAuthorization {
                let granted = try await notificationService.requestAuthorization()
                guard granted else {
                    reminderWarning = String(localized: "Notifiche disattivate: non riceverai i promemoria. Abilitale in Impostazioni > Notifiche.")
                    return
                }
            }
            notificationService.cancelExposureReminders()

            if session.configuration.advancedRemindersEnabled {
                try await notificationService.scheduleFlipReminder(
                    everyMinutes: session.configuration.flipIntervalMinutes
                )
                if let reapplySeconds = secondsUntilSunscreenReapplication(for: session), reapplySeconds > 0 {
                    try await notificationService.scheduleReapplyReminder(afterSeconds: reapplySeconds)
                }
                try await notificationService.scheduleHydrationReminder(
                    everyMinutes: Self.hydrationIntervalMinutes
                )
                // Doposole la sera: solo per le sessioni al sole, non per il lettino.
                if session.configuration.kind == .sun,
                   let afterSun = Self.afterSunTime() {
                    try await notificationService.scheduleAfterSunReminder(at: afterSun)
                }
            }

            let goalRemainingSeconds = session.configuration.plannedDurationMinutes * 60 - session.elapsedSeconds
            if goalRemainingSeconds > 0 {
                try await notificationService.scheduleGoalReminder(afterSeconds: Double(goalRemainingSeconds))
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
                if session.isPaused {
                    session.pausedSeconds += 1
                    self.active = session
                    continue
                }
                session.elapsedSeconds += 1
                switch session.currentSide {
                case .front:
                    session.frontExposureSeconds += 1
                case .back:
                    session.backExposureSeconds += 1
                }
                let spfFactor = self.currentSPFFactor(for: session)
                session.effectiveDose += session.currentUVIndex
                    * SafeExposure.wattsPerUVIndexUnit
                    / spfFactor
                self.active = session

                if session.configuration.advancedCompanionsEnabled,
                   session.elapsedSeconds % Self.liveActivityUpdateInterval == 0,
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

            if session.configuration.advancedCompanionsEnabled,
               let state = activityState() {
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

    private func currentSPFFactor(for session: ActiveSession) -> Double {
        guard session.configuration.spf > 1,
              let secondsUntilReapplication = secondsUntilSunscreenReapplication(for: session),
              secondsUntilReapplication > 0
        else {
            return 1
        }
        return min(session.configuration.spf, SafeExposure.maximumModeledSPF)
    }

    private func secondsUntilSunscreenReapplication(for session: ActiveSession) -> Double? {
        guard session.configuration.spf > 1,
              let appliedAt = session.sunscreenAppliedAtElapsedSeconds
        else {
            return nil
        }
        let secondsSinceApplication = max(0, session.elapsedSeconds - appliedAt)
        return Double(Self.reapplyIntervalSeconds - secondsSinceApplication)
    }
}
