import Foundation
import Observation
import WidgetKit
import SoleaCore

/// Tutti i valori mostrati dalla schermata Oggi, precalcolati in `load()` così
/// che ogni errore (posizione, WeatherKit, dati UV invalidi) emerga lì e venga
/// mostrato con retry — mai durante il render.
struct TodayMetrics {
    let conditions: UVConditions
    let burnRisk: BurnRisk
    let recommendedMinutesBareSkin: Double
    let recommendedMinutesSPF30: Double
    let recommendedPlan: SunExposureRecommendation
    let goalRecommendations: [SunExposureGoal: SunExposureRecommendation]
    let goldenHours: [DateInterval]
}

@MainActor
@Observable
final class TodayViewModel {
    enum State {
        case loading
        case loaded(TodayMetrics)
        case failed(message: String)
    }

    private(set) var state: State = .loading
    /// Avviso non bloccante: i dati in app sono validi ma i widget non sono
    /// stati aggiornati (es. App Group non configurato).
    private(set) var widgetSyncWarning: String?
    private(set) var goldenHourReminderMessage: String?
    private(set) var isSchedulingGoldenHourReminders = false

    private let locationService = LocationService()
    private let uvService = UVService()
    private let notificationService = NotificationService()

    /// `doseToday`: dose UV effettiva già accumulata oggi (somma delle sessioni).
    func load(phototype: Fitzpatrick, doseToday: Double, skinResponse: SkinResponse = .notLogged) async {
        state = .loading
        #if DEBUG
        if ScreenshotDemoSeeder.isEnabled {
            state = .loaded(Self.demoMetrics(
                phototype: phototype,
                doseToday: doseToday,
                skinResponse: skinResponse
            ))
            widgetSyncWarning = nil
            return
        }
        #endif
        do {
            let location = try await locationService.currentLocation()
            let conditions = try await uvService.conditions(for: location)
            let metrics = TodayMetrics(
                conditions: conditions,
                burnRisk: BurnRisk.level(
                    doseTodayJoulesPerSquareMeter: doseToday,
                    phototype: phototype,
                    currentUVIndex: conditions.currentUVIndex
                ),
                recommendedMinutesBareSkin: try SafeExposure.minutes(
                    phototype: phototype,
                    uvIndex: conditions.currentUVIndex
                ),
                recommendedMinutesSPF30: try SafeExposure.minutes(
                    phototype: phototype,
                    uvIndex: conditions.currentUVIndex,
                    spf: 30
                ),
                recommendedPlan: try SunExposureAdvisor.recommendedPlan(
                    phototype: phototype,
                    uvIndex: conditions.currentUVIndex,
                    doseAlreadyToday: doseToday,
                    skinResponse: skinResponse
                ),
                goalRecommendations: try Dictionary(uniqueKeysWithValues: SunExposureGoal.allCases.map { goal in
                    (
                        goal,
                        try SunExposureAdvisor.recommendation(
                            phototype: phototype,
                            uvIndex: conditions.currentUVIndex,
                            goal: goal,
                            doseAlreadyToday: doseToday,
                            skinResponse: skinResponse
                        )
                    )
                }),
                goldenHours: GoldenHours.windows(in: conditions.hourly, phototype: phototype)
            )
            state = .loaded(metrics)
            publishWidgetSnapshot(metrics: metrics, phototype: phototype)
        } catch {
            // Errore propagato fino alla UI con messaggio e retry, mai nascosto.
            state = .failed(message: error.localizedDescription)
        }
    }

    /// Scrive l'istantanea UV nell'App Group e fa ricaricare i widget.
    private func publishWidgetSnapshot(metrics: TodayMetrics, phototype: Fitzpatrick) {
        do {
            try SharedStore.save(UVSnapshot(
                currentUVIndex: metrics.conditions.currentUVIndex,
                safeMinutesBareSkin: metrics.recommendedMinutesBareSkin,
                burnRiskRawValue: metrics.burnRisk.rawValue,
                phototypeRawValue: phototype.rawValue,
                updatedAt: .now
            ))
            WidgetCenter.shared.reloadAllTimelines()
            widgetSyncWarning = nil
        } catch {
            widgetSyncWarning = String(
                localized: "Aggiornamento dei widget non riuscito: \(error.localizedDescription)"
            )
        }
    }

    @discardableResult
    func scheduleGoldenHourReminders(for metrics: TodayMetrics) async -> Bool {
        isSchedulingGoldenHourReminders = true
        defer { isSchedulingGoldenHourReminders = false }

        do {
            let granted = try await notificationService.requestStandardAuthorization()
            guard granted else {
                goldenHourReminderMessage = String(localized: "Notifiche disattivate: abilita Tanora in Impostazioni > Notifiche per ricevere gli avvisi sulle ore ideali.")
                return false
            }

            let scheduledCount = try await notificationService.scheduleGoldenHourReminders(
                for: metrics.goldenHours
            )
            if scheduledCount > 0 {
                goldenHourReminderMessage = String(localized: "Ti avviso 30 minuti prima e all'inizio della prossima fascia ideale.")
                return true
            } else {
                goldenHourReminderMessage = String(localized: "Nessuna fascia futura da programmare: riapri Oggi quando cambiano le previsioni UV.")
                return true
            }
        } catch {
            goldenHourReminderMessage = error.localizedDescription
            return false
        }
    }

    func cancelGoldenHourReminders() {
        notificationService.cancelGoldenHourReminders()
        goldenHourReminderMessage = nil
    }
}

#if DEBUG
private extension TodayViewModel {
    static func demoMetrics(
        phototype: Fitzpatrick,
        doseToday: Double,
        skinResponse: SkinResponse
    ) -> TodayMetrics {
        do {
            let now = Calendar.current.date(from: DateComponents(
                year: 2026,
                month: 6,
                day: 16,
                hour: 10
            )) ?? .now
            let hourly = (0..<18).map { offset in
                let uv = max(0.5, 7.2 - abs(Double(offset - 4)) * 0.7)
                return UVHour(
                    date: now.addingTimeInterval(TimeInterval(offset * 3600)),
                    uvIndex: uv
                )
            }
            let conditions = UVConditions(
                currentUVIndex: 6.4,
                hourly: hourly,
                fetchedAt: now
            )
            let plan = try SunExposureAdvisor.recommendedPlan(
                phototype: phototype,
                uvIndex: conditions.currentUVIndex,
                doseAlreadyToday: doseToday,
                skinResponse: skinResponse
            )

            let goalRecommendations = try Dictionary(uniqueKeysWithValues: SunExposureGoal.allCases.map { goal in
                (
                    goal,
                    try SunExposureAdvisor.recommendation(
                        phototype: phototype,
                        uvIndex: conditions.currentUVIndex,
                        goal: goal,
                        doseAlreadyToday: doseToday,
                        skinResponse: skinResponse
                    )
                )
            })

            return TodayMetrics(
                conditions: conditions,
                burnRisk: BurnRisk.level(
                    doseTodayJoulesPerSquareMeter: doseToday,
                    phototype: phototype,
                    currentUVIndex: conditions.currentUVIndex
                ),
                recommendedMinutesBareSkin: try SafeExposure.minutes(
                    phototype: phototype,
                    uvIndex: conditions.currentUVIndex
                ),
                recommendedMinutesSPF30: try SafeExposure.minutes(
                    phototype: phototype,
                    uvIndex: conditions.currentUVIndex,
                    spf: 30
                ),
                recommendedPlan: plan,
                goalRecommendations: goalRecommendations,
                goldenHours: GoldenHours.windows(in: hourly, phototype: phototype)
            )
        } catch {
            preconditionFailure("Invalid screenshot demo data: \(error)")
        }
    }
}
#endif
