import SwiftUI
import _SwiftData_SwiftUI
import Charts
import SoleaCore

struct TodayView: View {
    private struct FinishedSessionLog: Identifiable {
        let finished: FinishedSession
        let persistedSession: TanSession?

        var id: Date { finished.startedAt }
    }

    let phototype: Fitzpatrick
    let sessionManager: SessionManager

    @Environment(SoleaPlusStore.self) private var plusStore
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [TanSession]
    @State private var viewModel = TodayViewModel()
    @State private var showSessionSetup = false
    @State private var finishedSession: FinishedSessionLog?
    @State private var sharePayload: SharePayload?
    @State private var showPlusPaywall = false
    @State private var saveErrorMessage: String?
    @AppStorage("goldenHourRemindersEnabled") private var goldenHourRemindersEnabled = false
    @AppStorage("currentSkinResponse") private var currentSkinResponseRawValue = SkinResponse.comfortable.rawValue

    /// Dose UV effettiva già accumulata oggi tra sessioni salvate e sessione attiva.
    private var doseToday: Double {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let saved = sessions
            .filter { $0.startedAt >= startOfDay }
            .reduce(0) { $0 + $1.uvDose }
        return saved + (sessionManager.active?.effectiveDose ?? 0)
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessionManager.active != nil {
                    ActiveSessionView(
                        manager: sessionManager,
                        hasSoleaPlus: plusStore.hasPlus
                    ) { endSession() }
                } else {
                    switch viewModel.state {
                    case .loading:
                        ProgressView("Caricamento dati UV…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .failed(let message):
                        ContentUnavailableView {
                            Label("Dati UV non disponibili", systemImage: "sun.max.trianglebadge.exclamationmark")
                        } description: {
                            Text(message)
                        } actions: {
                            Button("Riprova") {
                                Task { await reloadToday() }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    case .loaded(let metrics):
                        content(metrics: metrics)
                    }
                }
            }
            .navigationTitle(
                sessionManager.active != nil
                    ? String(localized: "Sessione in corso")
                    : String(localized: "Oggi")
            )
            .task(id: currentSkinResponseRawValue) { await reloadToday() }
            .refreshable { await reloadToday() }
            .sheet(isPresented: $showSessionSetup) {
                if case .loaded(let metrics) = viewModel.state {
                    SessionSetupView(
                        currentUVIndex: metrics.conditions.currentUVIndex,
                        phototype: phototype,
                        suggestedGoal: metrics.recommendedPlan.goal,
                        currentSkinResponse: currentSkinResponse,
                        goalRecommendations: metrics.goalRecommendations,
                        hasSoleaPlus: plusStore.hasPlus
                    ) { configuration, initialUVIndex in
                        Task {
                            await sessionManager.start(
                                configuration: configuration,
                                phototype: phototype,
                                initialUVIndex: initialUVIndex
                            )
                        }
                    }
                }
            }
            .sheet(item: $finishedSession) { finished in
                SessionSummaryView(
                    session: finished.finished,
                    initialSkinResponse: finished.persistedSession?.skinResponse ?? .notLogged,
                    initialNote: finished.persistedSession?.noteText ?? "",
                    hasSoleaPlus: plusStore.hasPlus
                ) { skinResponse, note in
                    guard let persistedSession = finished.persistedSession else { return }
                    persistedSession.updateReflection(skinResponse: skinResponse, note: note)
                    try modelContext.save()
                    currentSkinResponseRawValue = skinResponse.rawValue
                }
            }
            .sheet(item: $sharePayload) { payload in
                ShareSheet(payload: payload)
            }
            .sheet(isPresented: $showPlusPaywall) {
                SoleaPlusPaywallView(source: "today_share")
            }
            .alert(
                "Salvataggio non riuscito",
                isPresented: Binding(
                    get: { saveErrorMessage != nil },
                    set: { if !$0 { saveErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? "")
            }
        }
    }

    private func reloadToday() async {
        await viewModel.load(
            phototype: phototype,
            doseToday: doseToday,
            skinResponse: currentSkinResponse
        )
        await rescheduleGoldenHourRemindersIfNeeded()
    }

    private func endSession() {
        guard let finished = sessionManager.end() else { return }
        let persistedSession = TanSession(
            startedAt: finished.startedAt,
            endedAt: finished.endedAt,
            spf: finished.configuration.spf,
            exposedZones: finished.configuration.zones,
            averageUVIndex: finished.averageUVIndex,
            uvDose: finished.effectiveDose,
            vitaminDIU: finished.vitaminDIU,
            phototype: finished.phototype,
            goal: finished.goal,
            frontExposureSeconds: finished.frontExposureSeconds,
            backExposureSeconds: finished.backExposureSeconds,
            plannedDurationMinutes: finished.plannedDurationMinutes,
            exposureSeconds: finished.exposureSeconds,
            pausedSeconds: finished.pausedSeconds
        )
        modelContext.insert(persistedSession)
        var savedSession: TanSession?
        do {
            try modelContext.save()
            savedSession = persistedSession
        } catch {
            // La sessione non persiste: l'utente lo deve sapere subito.
            saveErrorMessage = error.localizedDescription
        }
        finishedSession = FinishedSessionLog(finished: finished, persistedSession: savedSession)
        Task { await reloadToday() }
    }

    private func content(metrics: TodayMetrics) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                dailyCheckHero(metrics: metrics)
                skinResponseCard
                recommendedLimitCard(metrics: metrics)
                goldenHoursCard(metrics: metrics)
                forecastCard(metrics: metrics)
                if let warning = viewModel.widgetSyncWarning {
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .background(SoleaTheme.screenGradient.ignoresSafeArea())
        .tint(SoleaTheme.sunset)
    }

    // MARK: - Solea Check

    private var currentSkinResponse: SkinResponse {
        SkinResponse(rawValue: currentSkinResponseRawValue) ?? .comfortable
    }

    private var currentSkinResponseBinding: Binding<SkinResponse> {
        Binding(
            get: { currentSkinResponse },
            set: { currentSkinResponseRawValue = $0.rawValue }
        )
    }

    private func dailyCheckHero(metrics: TodayMetrics) -> some View {
        let recommendation = metrics.recommendedPlan
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("SOLEA CHECK", systemImage: "sparkles")
                    .font(.caption.bold())
                    .tracking(1.1)
                Spacer()
                Text(Date.now, format: .dateTime.day().month(.abbreviated))
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(planHeadline(recommendation))
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .monospacedDigit()
                Text(planUnit(recommendation))
                    .font(.title3.bold())
                    .foregroundStyle(.black.opacity(0.58))
            }

            Text(planExplanation(recommendation))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.black.opacity(0.68))

            primarySessionCTA(metrics: metrics)

            HStack(spacing: 8) {
                checkMetric(
                    value: metrics.conditions.currentUVIndex.formatted(.number.precision(.fractionLength(0))),
                    label: "UV",
                    icon: "sun.max.fill"
                )
                checkMetric(value: phototype.romanNumeral, label: "Fototipo", icon: "person.fill")
                checkMetric(
                    value: "\(recommendation.suggestedSPF)",
                    label: "SPF",
                    icon: "shield.lefthalf.filled"
                )
            }

            HStack {
                Label(riskText(metrics.burnRisk), systemImage: "circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(riskColor(metrics.burnRisk))
                Spacer()
                Button {
                    if plusStore.hasPlus {
                        shareDailyCheck(metrics)
                    } else {
                        showPlusPaywall = true
                    }
                } label: {
                    Label("Condividi", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .tint(.black)
                .accessibilityHint("Crea una storia verticale senza posizione o dati personali")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SoleaTheme.sunriseGradient, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.orange.opacity(0.18), lineWidth: 1)
        }
    }

    private func checkMetric(value: String, label: LocalizedStringKey, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.caption.bold())
            Text(value)
                .font(.headline.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(.black.opacity(0.54))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 14))
    }

    private var skinResponseCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Label("Come sta la pelle?", systemImage: "hand.raised.fill")
                    .font(.headline)

                Picker("Pelle adesso", selection: currentSkinResponseBinding) {
                    Text("Bene").tag(SkinResponse.comfortable)
                    Text("Calda").tag(SkinResponse.warm)
                    Text("Tira").tag(SkinResponse.tight)
                    Text("Rossa").tag(SkinResponse.red)
                }
                .pickerStyle(.segmented)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func riskText(_ risk: BurnRisk) -> String {
        switch risk {
        case .low: return String(localized: "Rischio scottatura basso")
        case .moderate: return String(localized: "Rischio scottatura moderato")
        case .high: return String(localized: "Rischio scottatura alto")
        }
    }

    private func riskColor(_ risk: BurnRisk) -> Color {
        switch risk {
        case .low:
            return Color(red: 0.05, green: 0.42, blue: 0.18)
        case .moderate:
            return Color(red: 0.64, green: 0.27, blue: 0.02)
        case .high:
            return Color(red: 0.72, green: 0.06, blue: 0.06)
        }
    }

    @MainActor
    private func shareDailyCheck(_ metrics: TodayMetrics) {
        let recommendation = metrics.recommendedPlan
        let uv = metrics.conditions.currentUVIndex.formatted(.number.precision(.fractionLength(0)))
        let card = ShareCardView(content: ShareCardContent(
            eyebrow: String(localized: "Il mio Solea Check di oggi"),
            headline: planHeadline(recommendation),
            unit: planUnit(recommendation),
            message: planExplanation(recommendation),
            metrics: [
                ShareCardMetric(icon: "sun.max.fill", value: uv, label: "UV"),
                ShareCardMetric(icon: "person.fill", value: phototype.romanNumeral, label: String(localized: "Fototipo")),
                ShareCardMetric(
                    icon: "shield.lefthalf.filled",
                    value: "\(recommendation.suggestedSPF)",
                    label: "SPF"
                )
            ],
            symbol: recommendation.minutes <= 0 ? "sun.horizon.fill" : "timer"
        ))
        sharePayload = renderSharePayload(
            content: card,
            caption: String(localized: "Il mio Solea Check di oggi: \(planHeadline(recommendation)) \(planUnit(recommendation)), UV \(uv), SPF \(recommendation.suggestedSPF). Stima informativa, non consiglio medico. ☀️"),
            source: "daily_check"
        )
    }

    private func goalTitle(_ goal: SunExposureGoal) -> LocalizedStringKey {
        switch goal {
        case .vitaminD: return "Vitamina D"
        case .gradualTan: return "Abbronzatura graduale"
        case .lowRisk: return "Sessione leggera"
        }
    }

    private func planHeadline(_ recommendation: SunExposureRecommendation) -> String {
        if recommendation.minutes.isInfinite {
            return String(localized: "UV basso")
        }
        if recommendation.minutes <= 0 {
            return String(localized: "Ombra")
        }
        return formattedMinutes(recommendation.minutes)
    }

    private func planUnit(_ recommendation: SunExposureRecommendation) -> String {
        if recommendation.minutes <= 0 {
            return String(localized: "oggi")
        }
        return String(localized: "al sole")
    }

    private func planExplanation(_ recommendation: SunExposureRecommendation) -> String {
        switch currentSkinResponse {
        case .red:
            return String(localized: "Pelle arrossata: niente sole diretto oggi, idratazione e doposole.")
        case .tight:
            return String(localized: "La pelle tira: meglio fermarsi, stare all'ombra e recuperare.")
        case .warm:
            return String(localized: "Pelle calda: piano ridotto, senza forzare l'abbronzatura.")
        case .comfortable, .notLogged:
            break
        }

        if recommendation.minutes.isInfinite {
            return String(localized: "UV molto basso: puoi stare fuori, ma l'effetto su abbronzatura e vitamina D sarà minimo.")
        }
        if recommendation.minutes <= 0 {
            return String(localized: "Hai già preso abbastanza UV oggi: ombra, acqua e doposole.")
        }

        let vitaminD = Int(recommendation.estimatedVitaminDIU.rounded())
        switch recommendation.goal {
        case .vitaminD:
            return String(localized: "Obiettivo vitamina D: circa \(vitaminD) IU, poi protezione o ombra.")
        case .gradualTan:
            return String(localized: "Dose graduale: il tan resta una risposta agli UV, quindi Solea ferma prima del rossore.")
        case .lowRisk:
            return String(localized: "Dose ridotta per le giornate in cui vuoi minimizzare il rischio senza forzare l'abbronzatura.")
        }
    }

    private func zonesText(_ zones: ExposedZones) -> String {
        var names: [String] = []
        if zones.contains(.face) { names.append(String(localized: "viso")) }
        if zones.contains(.torso) { names.append(String(localized: "petto")) }
        if zones.contains(.back) { names.append(String(localized: "schiena")) }
        if zones.contains(.arms) { names.append(String(localized: "braccia")) }
        if zones.contains(.legs) { names.append(String(localized: "gambe")) }
        return names.joined(separator: ", ")
    }

    // MARK: - Stop sicurezza

    private func recommendedLimitCard(metrics: TodayMetrics) -> some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Stop sicurezza al sole")
                    .font(.headline)
                HStack {
                    recommendedLimitColumn(title: "Senza protezione", minutes: metrics.recommendedMinutesBareSkin)
                    Divider()
                    recommendedLimitColumn(title: "Con SPF 30", minutes: metrics.recommendedMinutesSPF30)
                }
            }
        }
    }

    private func recommendedLimitColumn(title: LocalizedStringKey, minutes: Double) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formattedMinutes(minutes))
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity)
    }

    private func formattedMinutes(_ minutes: Double) -> String {
        if minutes.isInfinite {
            return String(localized: "UV trascurabile")
        }
        if minutes >= 120 {
            let hours = minutes / 60
            return String(localized: "\(hours.formatted(.number.precision(.fractionLength(0...1)))) h")
        }
        return String(localized: "\(Int(minutes.rounded())) min")
    }

    // MARK: - Ore ideali

    private func goldenHoursCard(metrics: TodayMetrics) -> some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Label("Ore ideali", systemImage: "sparkles")
                    .font(.headline)
                if metrics.goldenHours.isEmpty {
                    Text("Nessuna finestra ideale nelle prossime 24 ore per il tuo fototipo.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(metrics.goldenHours, id: \.self) { window in
                        HStack {
                            Image(systemName: "sun.haze.fill")
                                .foregroundStyle(.orange)
                            Text(intervalText(window))
                                .font(.subheadline.monospacedDigit())
                        }
                    }
                    Text("Le fasce più prudenti tra quelle utili per il tuo fototipo.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Divider()
                goldenHourReminderControls(metrics: metrics)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func goldenHourReminderControls(metrics: TodayMetrics) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Label(
                    goldenHourRemindersEnabled ? "Avvisi ore ideali attivi" : "Avvisami per le ore ideali",
                    systemImage: goldenHourRemindersEnabled ? "bell.badge.fill" : "bell"
                )
                .font(.subheadline.weight(.semibold))

                Spacer()

                if viewModel.isSchedulingGoldenHourReminders {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button(goldenHourRemindersEnabled ? "Disattiva" : "Attiva") {
                        if goldenHourRemindersEnabled {
                            disableGoldenHourReminders()
                        } else {
                            enableGoldenHourReminders(metrics: metrics)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            Text("Solea ti richiama 30 minuti prima e quando inizia una finestra ideale, così puoi entrare nell'app e avviare una sessione guidata.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let message = viewModel.goldenHourReminderMessage {
                Label(message, systemImage: goldenHourRemindersEnabled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(goldenHourRemindersEnabled ? .green : .orange)
            }
        }
    }

    private func enableGoldenHourReminders(metrics: TodayMetrics) {
        Task {
            let scheduled = await viewModel.scheduleGoldenHourReminders(for: metrics)
            goldenHourRemindersEnabled = scheduled
        }
    }

    private func disableGoldenHourReminders() {
        viewModel.cancelGoldenHourReminders()
        goldenHourRemindersEnabled = false
    }

    private func rescheduleGoldenHourRemindersIfNeeded() async {
        guard goldenHourRemindersEnabled,
              case .loaded(let metrics) = viewModel.state
        else {
            return
        }
        let scheduled = await viewModel.scheduleGoldenHourReminders(for: metrics)
        goldenHourRemindersEnabled = scheduled
    }

    private func intervalText(_ interval: DateInterval) -> String {
        let start = interval.start.formatted(date: .omitted, time: .shortened)
        let end = interval.end.formatted(date: .omitted, time: .shortened)
        return "\(start) – \(end)"
    }

    // MARK: - Previsione oraria

    private func forecastCard(metrics: TodayMetrics) -> some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Previsione UV")
                    .font(.headline)
                Chart(metrics.conditions.hourly.prefix(12), id: \.date) { hour in
                    BarMark(
                        x: .value("Ora", hour.date, unit: .hour),
                        y: .value("UV", hour.uvIndex)
                    )
                    .foregroundStyle(barColor(uv: hour.uvIndex))
                }
                .chartYScale(domain: 0...11)
                .frame(height: 160)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func barColor(uv: Double) -> Color {
        switch uv {
        case ..<3: return .green
        case ..<6: return .yellow
        case ..<8: return .orange
        case ..<11: return .red
        default: return .purple
        }
    }

    // MARK: - CTA sessione

    private func primarySessionCTA(metrics: TodayMetrics) -> some View {
        let title: LocalizedStringKey = metrics.recommendedPlan.minutes <= 0
            ? "Vedi piano sicuro"
            : "Avvia sessione"
        return Button {
            showSessionSetup = true
        } label: {
            HStack(spacing: 10) {
                Label(
                    title,
                    systemImage: metrics.recommendedPlan.minutes <= 0 ? "sun.horizon.fill" : "timer"
                )
                .font(.headline)
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(.black.opacity(0.84), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Apre il piano con durata, SPF e promemoria suggeriti")
    }

    // MARK: - Helpers

    private func card(@ViewBuilder content: () -> some View) -> some View {
        content()
            .padding()
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
