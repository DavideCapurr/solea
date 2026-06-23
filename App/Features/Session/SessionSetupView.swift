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
        let recommendation = goalRecommendations[suggestedGoal]
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
            Form {
                Section("Piano consigliato") {
                    LabeledContent("Azione") {
                        Text(setupActionText)
                            .bold()
                    }
                    LabeledContent("Obiettivo scelto") {
                        Text(goalTitle(goal))
                    }
                    LabeledContent("Pelle") {
                        Text(skinResponseTitle(currentSkinResponse))
                    }
                    Text(setupReasonText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if targetMinutes > 0 {
                        Stepper(value: $targetMinutes, in: 5...Self.targetRange.upperBound, step: 5) {
                            LabeledContent("Durata obiettivo") {
                                Text("\(targetMinutes) min")
                                    .bold()
                            }
                        }
                    } else {
                        Label("Oggi niente sole diretto", systemImage: "sun.horizon")
                            .foregroundStyle(.orange)
                    }
                }

                Section("Tipo di sessione") {
                    Picker("Tipo", selection: $kind) {
                        Text("Sole").tag(SessionKind.sun)
                        Text("Lettino").tag(SessionKind.solarium)
                    }
                    .pickerStyle(.segmented)

                    if kind == .solarium {
                        Picker("Potenza lampade", selection: $solariumPower) {
                            Text("Bassa").tag(SolariumPower.low)
                            Text("Media").tag(SolariumPower.medium)
                            Text("Alta").tag(SolariumPower.high)
                            Text("Molto alta").tag(SolariumPower.veryHigh)
                        }
                    }
                }

                Section("Protezione") {
                    Picker("SPF applicato", selection: spfBinding) {
                        ForEach(Self.spfOptions, id: \.self) { value in
                            if value == 1 {
                                Text("Nessuna").tag(value)
                            } else {
                                Text("SPF \(Int(value))").tag(value)
                            }
                        }
                    }
                }

                Section("Zone esposte") {
                    zoneToggle("Viso", zone: .face)
                    zoneToggle("Petto", zone: .torso)
                    zoneToggle("Schiena", zone: .back)
                    zoneToggle("Braccia", zone: .arms)
                    zoneToggle("Gambe", zone: .legs)
                }

                Section("Promemoria") {
                    if hasSoleaPlus {
                        Picker("Girati ogni", selection: $flipIntervalMinutes) {
                            ForEach(Self.flipOptions, id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                    } else {
                        LabeledContent("Timer base") {
                            Text("20 min")
                                .foregroundStyle(.secondary)
                        }
                        Text("Gli alert di sicurezza restano attivi. Solea Plus sblocca promemoria personalizzati per lato, SPF, acqua e obiettivo.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    recommendedLimitPreview
                } footer: {
                    Text(limitExplanation)
                }
            }
            .navigationTitle("Piano sessione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Avvia") {
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
                    .disabled(zones.isEmpty || targetMinutes == 0)
                }
            }
            .onChange(of: kind) { _, _ in applyRecommendation(resetUserChoices: false) }
            .onChange(of: solariumPower) { _, _ in applyRecommendation(resetUserChoices: false) }
        }
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
        if let recommendation {
            goal = recommendation.goal
        }
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
        return try? SunExposureAdvisor.recommendedPlan(
            phototype: phototype,
            uvIndex: effectiveUVIndex,
            skinResponse: currentSkinResponse
        )
    }

    private var goalRecommendationMinutes: Double? {
        goalRecommendation?.minutes
    }

    private static func targetMinutes(from recommendation: Double?) -> Int {
        guard let recommendation, recommendation.isFinite else { return 20 }
        guard recommendation > 0 else { return 0 }
        let rounded = Int((recommendation / 5).rounded()) * 5
        return min(targetRange.upperBound, max(targetRange.lowerBound, rounded))
    }

    private static func nearestSPF(to value: Int) -> Double {
        spfOptions.min(by: { abs($0 - Double(value)) < abs($1 - Double(value)) }) ?? 30
    }

    private func goalTitle(_ goal: SunExposureGoal) -> LocalizedStringKey {
        switch goal {
        case .vitaminD: return "Vitamina D"
        case .gradualTan: return "Abbronzatura graduale"
        case .lowRisk: return "Prudenza"
        }
    }

    private var setupActionText: String {
        guard let minutes = goalRecommendationMinutes else {
            return String(localized: "Controlla i dati")
        }
        if minutes.isInfinite {
            return String(localized: "Stai all'aperto senza forzare l'abbronzatura")
        }
        if minutes <= 0 {
            return String(localized: "Ombra e recupero")
        }
        return String(localized: "\(Int(minutes.rounded())) min al sole")
    }

    private var setupReasonText: String {
        switch currentSkinResponse {
        case .red:
            return String(localized: "La pelle è arrossata: Solea blocca il sole diretto per oggi.")
        case .tight:
            return String(localized: "La pelle tira: il recupero viene prima dell'abbronzatura.")
        case .warm:
            return String(localized: "La pelle è calda: Solea riduce automaticamente dose e obiettivo.")
        case .comfortable, .notLogged:
            break
        }

        guard let recommendation = goalRecommendation else {
            return String(localized: "Dati insufficienti per costruire un piano affidabile.")
        }
        switch recommendation.goal {
        case .vitaminD:
            return String(localized: "UV basso o moderato: Solea privilegia una breve esposizione utile.")
        case .gradualTan:
            return String(localized: "Fototipo e UV permettono una sessione graduale sotto soglia prudente.")
        case .lowRisk:
            return String(localized: "UV, dose di oggi o pelle suggeriscono una sessione ridotta.")
        }
    }

    private var limitExplanation: String {
        if kind == .sun {
            return String(localized: "Stimato per il tuo fototipo \(phototype.romanNumeral) all'UV attuale; si aggiorna se l'UV cambia.")
        }
        return String(localized: "Stimato per il tuo fototipo \(phototype.romanNumeral) in base all'equivalente UV della potenza scelta. È una stima: segui sempre le indicazioni del centro.")
    }

    private func skinResponseTitle(_ response: SkinResponse) -> LocalizedStringKey {
        switch response {
        case .notLogged: return "Non registrata"
        case .comfortable: return "Bene"
        case .warm: return "Calda"
        case .tight: return "Tira"
        case .red: return "Arrossata"
        }
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

    @ViewBuilder
    private var recommendedLimitPreview: some View {
        if let recommendation = goalRecommendationMinutes {
            LabeledContent("Consiglio per obiettivo") {
                Text(recommendationText(recommendation))
                    .bold()
            }
        }

        switch Result(catching: {
            try SafeExposure.minutes(phototype: phototype, uvIndex: effectiveUVIndex, spf: spf)
        }) {
        case .success(let minutes):
            LabeledContent("Limite prudente stimato") {
                Text(minutes.isInfinite
                     ? String(localized: "UV trascurabile")
                     : String(localized: "\(Int(minutes.rounded())) min"))
                .bold()
            }
        case .failure(let error):
            // UV o SPF invalidi non vanno mascherati con un numero plausibile.
            Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
        }
    }

    private func recommendationText(_ minutes: Double) -> String {
        if minutes.isInfinite {
            return String(localized: "UV trascurabile")
        }
        if minutes <= 0 {
            return String(localized: "Già coperto oggi")
        }
        return String(localized: "\(Int(minutes.rounded())) min")
    }
}
