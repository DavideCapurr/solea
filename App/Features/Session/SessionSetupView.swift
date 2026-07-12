import SwiftUI
import SoleaCore

struct SessionSetupView: View {
    let currentUVIndex: Double
    let phototype: Fitzpatrick
    let currentSkinResponse: SkinResponse
    let goalRecommendations: [SunExposureGoal: SunExposureRecommendation]
    let hasSoleaPlus: Bool
    /// Restituisce la configurazione e l'indice UV iniziale (sole = WeatherKit,
    /// lettino = UV-equivalente della potenza scelta).
    let onStart: (SessionConfiguration, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var goal: SunExposureGoal
    @State private var kind: SessionKind = .sun
    @State private var solariumPower: SolariumPower = .medium
    @State private var spf: Double = 30
    @State private var zones: ExposedZones = [.torso, .back, .arms, .legs]
    @State private var flipIntervalMinutes = 20
    @State private var targetMinutes: Int
    @State private var didCustomizeSPF = false
    @State private var didCustomizeZones = false
    @State private var isApplyingRecommendation = false
    @State private var showDetails = false

    private static let spfOptions: [Double] = [1, 6, 10, 15, 20, 30, 50]
    private static let flipOptions = [15, 20, 30, 45]
    private static let targetRange = 0...120

    init(
        currentUVIndex: Double,
        phototype: Fitzpatrick,
        suggestedGoal: SunExposureGoal = .gradualTan,
        currentSkinResponse: SkinResponse = .notLogged,
        goalRecommendations: [SunExposureGoal: SunExposureRecommendation] = [:],
        hasSoleaPlus: Bool = false,
        onStart: @escaping (SessionConfiguration, Double) -> Void
    ) {
        self.currentUVIndex = currentUVIndex
        self.phototype = phototype
        self.currentSkinResponse = currentSkinResponse
        self.goalRecommendations = goalRecommendations
        self.hasSoleaPlus = hasSoleaPlus
        self.onStart = onStart
        let recommendation = goalRecommendations[suggestedGoal] ?? (try? SunExposureAdvisor.recommendation(
            phototype: phototype,
            uvIndex: currentUVIndex,
            goal: suggestedGoal,
            skinResponse: currentSkinResponse
        ))
        _goal = State(initialValue: suggestedGoal)
        _spf = State(initialValue: Self.nearestSPF(to: recommendation?.suggestedSPF ?? 30))
        _zones = State(initialValue: recommendation?.zones ?? SunExposureAdvisor.defaultZones(for: suggestedGoal))
        _targetMinutes = State(initialValue: Self.targetMinutes(from: recommendation?.minutes))
    }

    /// UV effettivo usato per i calcoli: WeatherKit al sole, potenza al lettino.
    private var effectiveUVIndex: Double {
        kind == .sun ? currentUVIndex : solariumPower.equivalentUVIndex
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    planHero
                    goalPicker
                    detailsDisclosure
                }
                .padding()
                .padding(.bottom, 96)
            }
            .background(SoleaTheme.screenGradient.ignoresSafeArea())
            .navigationTitle("Piano sessione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                startFooter
            }
            .onChange(of: goal) { _, _ in applyRecommendation(resetUserChoices: true) }
            .onChange(of: kind) { _, _ in applyRecommendation(resetUserChoices: false) }
            .onChange(of: solariumPower) { _, _ in applyRecommendation(resetUserChoices: false) }
        }
    }

    private var planHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("PIANO TAN", systemImage: "sparkles")
                    .font(.caption.bold())
                    .tracking(1.1)
                Spacer()
                Text("UV \(effectiveUVIndex.formatted(.number.precision(.fractionLength(0...1))))")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.black.opacity(0.6))
            }

            Text(setupActionText)
                .font(.system(size: 42, weight: .black, design: .rounded))
                .minimumScaleFactor(0.62)
                .lineLimit(2)

            Text(setupReasonText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.black.opacity(0.68))

            VStack(spacing: 12) {
                planRow("Timer", value: timerText, icon: "timer")
                planRow("Protezione", value: protectionText, icon: "shield.lefthalf.filled")
                planRow("Dopo", value: afterTimerText, icon: "beach.umbrella.fill")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SoleaTheme.sunriseGradient, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.orange.opacity(0.18), lineWidth: 1)
        }
    }

    private var goalPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Obiettivo")
                .font(.headline)
            Picker("Obiettivo", selection: $goal) {
                Text("Vitamina D").tag(SunExposureGoal.vitaminD)
                Text("Abbronzatura").tag(SunExposureGoal.gradualTan)
                Text("Leggera").tag(SunExposureGoal.lowRisk)
            }
            .pickerStyle(.segmented)

            Text(goalHelpText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var detailsDisclosure: some View {
        DisclosureGroup(isExpanded: $showDetails) {
            VStack(alignment: .leading, spacing: 16) {
                Divider()

                Picker("Tipo", selection: $kind) {
                    Text("Sole").tag(SessionKind.sun)
                    Text("Lettino").tag(SessionKind.solarium)
                }
                .pickerStyle(.segmented)

                if kind == .solarium {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Potenza lampade", selection: $solariumPower) {
                            Text("Bassa").tag(SolariumPower.low)
                            Text("Media").tag(SolariumPower.medium)
                            Text("Alta").tag(SolariumPower.high)
                            Text("Molto alta").tag(SolariumPower.veryHigh)
                        }
                        .pickerStyle(.menu)
                        Text("Abbronzo non consiglia i lettini: sono UV concentrati. Se procedi, usa protezioni oculari e segui le indicazioni del centro.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Picker("SPF usato", selection: spfBinding) {
                    ForEach(Self.spfOptions, id: \.self) { value in
                        if value == 1 {
                            Text("Nessuna").tag(value)
                        } else {
                            Text("SPF \(Int(value))").tag(value)
                        }
                    }
                }
                .pickerStyle(.menu)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Zone esposte")
                        .font(.subheadline.weight(.semibold))
                    zoneToggle("Viso", zone: .face)
                    zoneToggle("Petto", zone: .torso)
                    zoneToggle("Schiena", zone: .back)
                    zoneToggle("Braccia", zone: .arms)
                    zoneToggle("Gambe", zone: .legs)
                }

                if hasSoleaPlus {
                    Picker("Girati ogni", selection: $flipIntervalMinutes) {
                        ForEach(Self.flipOptions, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                    .pickerStyle(.menu)
                } else {
                    Label("Stop-obiettivo e stop di sicurezza restano attivi. Plus aggiunge promemoria per lato, SPF e acqua.", systemImage: "bell")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 10)
        } label: {
            Label("Dettagli pratici", systemImage: "slider.horizontal.3")
                .font(.headline)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var startFooter: some View {
        VStack(spacing: 8) {
            if zones.isEmpty || targetMinutes == 0 {
                Text(startDisabledText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                startSession()
            } label: {
                Label(startButtonTitle, systemImage: targetMinutes > 0 ? "timer" : "sun.horizon.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(zones.isEmpty || targetMinutes == 0)
        }
        .padding()
        .background(.regularMaterial)
    }

    private var spfBinding: Binding<Double> {
        Binding(
            get: { spf },
            set: { newValue in
                spf = newValue
                if !isApplyingRecommendation {
                    didCustomizeSPF = true
                }
            }
        )
    }

    private func applyRecommendation(resetUserChoices: Bool) {
        let recommendation = goalRecommendation
        targetMinutes = Self.targetMinutes(from: recommendation?.minutes)

        let shouldApplySPF = resetUserChoices || !didCustomizeSPF
        let shouldApplyZones = resetUserChoices || !didCustomizeZones
        isApplyingRecommendation = true
        if shouldApplySPF {
            spf = Self.nearestSPF(to: recommendation?.suggestedSPF ?? Int(spf))
        }
        if shouldApplyZones {
            zones = recommendation?.zones ?? SunExposureAdvisor.defaultZones(for: goal)
        }
        isApplyingRecommendation = false

        if resetUserChoices {
            didCustomizeSPF = false
            didCustomizeZones = false
        }
    }

    private var goalRecommendation: SunExposureRecommendation? {
        if kind == .sun, let recommendation = goalRecommendations[goal] {
            return recommendation
        }
        return try? SunExposureAdvisor.recommendation(
            phototype: phototype,
            uvIndex: effectiveUVIndex,
            goal: goal,
            skinResponse: currentSkinResponse
        )
    }

    private static func targetMinutes(from recommendation: Double?) -> Int {
        guard let recommendation, recommendation.isFinite else { return 0 }
        guard recommendation > 0 else { return 0 }
        let wholeMinutes = Int(recommendation.rounded(.down))
        return min(targetRange.upperBound, max(targetRange.lowerBound, wholeMinutes))
    }

    private static func nearestSPF(to value: Int) -> Double {
        spfOptions.min(by: { abs($0 - Double(value)) < abs($1 - Double(value)) }) ?? 30
    }

    private func goalTitleText(_ goal: SunExposureGoal) -> String {
        switch goal {
        case .vitaminD: return String(localized: "vitamina D")
        case .gradualTan: return String(localized: "abbronzatura graduale")
        case .lowRisk: return String(localized: "sessione leggera")
        }
    }

    private var setupActionText: String {
        guard let recommendation = goalRecommendation else {
            return String(localized: "Controlla i dati")
        }
        if recommendation.minutes.isInfinite {
            return String(localized: "Nessun timer")
        }
        if targetMinutes <= 0 {
            return String(localized: "Ombra e recupero")
        }
        return String(localized: "\(targetMinutes) min al sole")
    }

    private var setupReasonText: String {
        switch currentSkinResponse {
        case .red:
            return String(localized: "La pelle è arrossata: Abbronzo blocca il sole diretto per oggi.")
        case .tight:
            return String(localized: "La pelle tira: il recupero viene prima dell'abbronzatura.")
        case .warm:
            return String(localized: "La pelle è calda: Abbronzo riduce automaticamente dose e obiettivo.")
        case .comfortable, .notLogged:
            break
        }

        guard let recommendation = goalRecommendation else {
            return String(localized: "Dati insufficienti per costruire un piano affidabile.")
        }
        if recommendation.minutes.isInfinite {
            return String(localized: "UV trascurabile: puoi stare fuori, ma abbronzatura e vitamina D saranno minime.")
        }
        if recommendation.minutes > 0, targetMinutes == 0 {
            return String(localized: "Il tempo calcolato è sotto un minuto: meglio ombra o protezione.")
        }

        switch recommendation.goal {
        case .vitaminD:
            return String(localized: "Timer scelto per \(goalTitleText(goal)), fototipo \(phototype.romanNumeral), UV attuale e pelle \(skinResponseTitleText(currentSkinResponse)).")
        case .gradualTan:
            return String(localized: "Dose graduale: il tan resta una risposta agli UV, quindi Abbronzo ferma prima del rossore.")
        case .lowRisk:
            return String(localized: "Dose ridotta per minimizzare il rischio oggi, in base a UV, fototipo e pelle.")
        }
    }

    private func skinResponseTitleText(_ response: SkinResponse) -> String {
        switch response {
        case .notLogged: return String(localized: "non registrata")
        case .comfortable: return String(localized: "bene")
        case .warm: return String(localized: "calda")
        case .tight: return String(localized: "che tira")
        case .red: return String(localized: "arrossata")
        }
    }

    private var goalHelpText: String {
        switch goal {
        case .vitaminD:
            return String(localized: "Timer breve per vitamina D; per carenze o dubbi servono esami e indicazioni mediche, non più sole.")
        case .gradualTan:
            return String(localized: "Sessione breve e progressiva: niente obiettivo di rossore, niente rincorsa al colore.")
        case .lowRisk:
            return String(localized: "La scelta più leggera quando UV, pelle o dose di oggi suggeriscono di ridurre.")
        }
    }

    private var timerText: String {
        guard let recommendation = goalRecommendation else {
            return String(localized: "Non disponibile")
        }
        if recommendation.minutes.isInfinite {
            return String(localized: "Non necessario con questo UV")
        }
        if targetMinutes <= 0 {
            return String(localized: "Niente sole diretto")
        }
        return String(localized: "\(targetMinutes) min, poi stop")
    }

    private var protectionText: String {
        if targetMinutes <= 0 {
            return String(localized: "Ombra, indumenti e recupero")
        }
        if kind == .solarium {
            return String(localized: "Occhiali protettivi e regole del centro")
        }
        let spfLabel = spf == 1 ? String(localized: "protezione fisica") : String(localized: "SPF \(Int(spf))")
        if effectiveUVIndex >= 8 {
            return String(localized: "\(spfLabel), cappello/occhiali, ombra appena finito")
        }
        if effectiveUVIndex >= 3 {
            return String(localized: "\(spfLabel), cappello/occhiali se resti fuori")
        }
        return String(localized: "UV basso: proteggiti se resti fuori a lungo")
    }

    private var afterTimerText: String {
        guard let recommendation = goalRecommendation else {
            return String(localized: "Controlla i dati UV")
        }
        if recommendation.minutes.isInfinite {
            return String(localized: "Non forzare: l'effetto su tan e vitamina D è minimo")
        }
        if targetMinutes <= 0 {
            return String(localized: "Acqua, doposole e niente UV diretto")
        }
        return String(localized: "Ombra o protezione; non aggiungere minuti oggi")
    }

    private var startButtonTitle: LocalizedStringKey {
        targetMinutes > 0 ? "Avvia timer Abbronzo" : "Ombra oggi"
    }

    private var startDisabledText: String {
        if zones.isEmpty {
            return String(localized: "Seleziona almeno una zona esposta nei dettagli pratici.")
        }
        return String(localized: "Oggi Abbronzo non consiglia un timer al sole diretto.")
    }

    private func planRow(_ title: LocalizedStringKey, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.bold())
                .frame(width: 22)
                .foregroundStyle(.black.opacity(0.65))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.black.opacity(0.54))
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.78))
            }
            Spacer(minLength: 0)
        }
    }

    private func startSession() {
        onStart(
            SessionConfiguration(
                spf: spf,
                zones: zones,
                flipIntervalMinutes: flipIntervalMinutes,
                kind: kind,
                goal: goal,
                plannedDurationMinutes: targetMinutes,
                advancedRemindersEnabled: hasSoleaPlus,
                advancedCompanionsEnabled: hasSoleaPlus
            ),
            effectiveUVIndex
        )
        dismiss()
    }

    private func zoneToggle(_ title: LocalizedStringKey, zone: ExposedZones) -> some View {
        Toggle(title, isOn: Binding(
            get: { zones.contains(zone) },
            set: { isOn in
                if !isApplyingRecommendation {
                    didCustomizeZones = true
                }
                if isOn { zones.insert(zone) } else { zones.remove(zone) }
            }
        ))
    }
}
