import SwiftUI
import SoleaCore

struct SessionSummaryView: View {
    private enum HealthSaveState: Equatable {
        case idle
        case saving
        case saved
        case failed(String)
    }

    private enum ReflectionSaveState: Equatable {
        case idle
        case saved
        case failed(String)
    }

    let session: FinishedSession
    let hasSoleaPlus: Bool
    let onSaveReflection: ((SkinResponse, String) throws -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var healthSaveState: HealthSaveState = .idle
    @State private var reflectionSaveState: ReflectionSaveState = .idle
    @State private var skinResponse: SkinResponse
    @State private var note: String
    @State private var sharePayload: SharePayload?
    @State private var showPlusPaywall = false
    private let healthKitService = HealthKitService()

    init(
        session: FinishedSession,
        initialSkinResponse: SkinResponse = .notLogged,
        initialNote: String = "",
        hasSoleaPlus: Bool = false,
        onSaveReflection: ((SkinResponse, String) throws -> Void)? = nil
    ) {
        self.session = session
        self.hasSoleaPlus = hasSoleaPlus
        self.onSaveReflection = onSaveReflection
        _skinResponse = State(initialValue: initialSkinResponse == .notLogged ? .comfortable : initialSkinResponse)
        _note = State(initialValue: initialNote)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    sessionHighlight
                }
                .listRowBackground(Color.orange.opacity(0.12))

                Section("Riepilogo") {
                    LabeledContent("Obiettivo") {
                        Text(goalTitle(session.goal))
                    }
                    LabeledContent("Durata") {
                        Text(sessionDurationText)
                    }
                    if session.pausedSeconds > 0 {
                        LabeledContent("Pausa") {
                            Text(durationText(seconds: session.pausedSeconds))
                        }
                    }
                    LabeledContent("Timer obiettivo") {
                        Text("\(session.plannedDurationMinutes) min")
                    }
                    LabeledContent("UV medio") {
                        Text(session.averageUVIndex, format: .number.precision(.fractionLength(1)))
                    }
                    LabeledContent("Dose UV assorbita") {
                        Text("\(Int(session.effectiveDose.rounded())) J/m²")
                    }
                    LabeledContent("Quota della MED") {
                        Text(session.fractionOfMED, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(session.fractionOfMED < SafeExposure.recommendedLimitFractionOfMED ? .primary : Color.red)
                    }
                    LabeledContent("Vitamina D stimata") {
                        Text("≈ \(Int(session.vitaminDIU.rounded())) IU")
                    }
                }

                Section("Uniformità") {
                    LabeledContent("Fronte") {
                        Text(durationText(seconds: session.frontExposureSeconds))
                    }
                    LabeledContent("Retro") {
                        Text(durationText(seconds: session.backExposureSeconds))
                    }
                    Text(sideBalanceText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Lettura") {
                    Text(sessionInsight)
                        .font(.subheadline)
                    Text(nextStepText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if onSaveReflection != nil {
                    Section {
                        Picker("Sensazione", selection: $skinResponse) {
                            ForEach(trackedSkinResponses) { response in
                                Text(skinResponseTitle(response)).tag(response)
                            }
                        }

                        TextField("Nota per la prossima sessione", text: $note, axis: .vertical)
                            .lineLimit(2...4)

                        reflectionSection
                    } header: {
                        Text("Come sta la pelle?")
                    } footer: {
                        Text("Segnare sensazioni e note ti aiuta a capire quali durate, UV e SPF funzionano meglio per te.")
                    }
                }

                Section {
                    healthSection
                } footer: {
                    Text("Salva su Apple Health il tempo alla luce del giorno della sessione.")
                }
            }
            .navigationTitle("Sessione completata")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
            }
            .sheet(item: $sharePayload) { payload in
                ShareSheet(payload: payload)
            }
            .sheet(isPresented: $showPlusPaywall) {
                SoleaPlusPaywallView(source: "session_share")
            }
        }
    }

    private var sessionHighlight: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("TAN MOMENT", systemImage: "sparkles")
                .font(.caption.bold())
                .tracking(1.1)
                .foregroundStyle(.orange)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(sessionDurationText)
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .monospacedDigit()
                Text("di sole intelligente")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Text(sessionInsight)
                .font(.subheadline.weight(.medium))

            Button {
                if hasSoleaPlus {
                    shareSession()
                } else {
                    showPlusPaywall = true
                }
            } label: {
                Label("Condividi la sessione", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var reflectionSection: some View {
        switch reflectionSaveState {
        case .idle:
            Button {
                saveReflection()
            } label: {
                Label("Salva riflessione", systemImage: "square.and.pencil")
            }
        case .saved:
            Label("Riflessione salvata", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed(let message):
            VStack(alignment: .leading, spacing: 8) {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                Button("Riprova") { saveReflection() }
            }
        }
    }

    @ViewBuilder
    private var healthSection: some View {
        switch healthSaveState {
        case .idle:
            Button {
                saveToHealth()
            } label: {
                Label("Salva su Salute", systemImage: "heart.fill")
            }
        case .saving:
            HStack {
                ProgressView()
                Text("Salvataggio in corso…")
            }
        case .saved:
            Label("Salvato su Salute", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed(let message):
            VStack(alignment: .leading, spacing: 8) {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                Button("Riprova") { saveToHealth() }
            }
        }
    }

    private func saveToHealth() {
        healthSaveState = .saving
        Task {
            do {
                try await healthKitService.saveSession(session)
                healthSaveState = .saved
            } catch {
                healthSaveState = .failed(error.localizedDescription)
            }
        }
    }

    private func saveReflection() {
        do {
            try onSaveReflection?(skinResponse, note)
            reflectionSaveState = .saved
        } catch {
            reflectionSaveState = .failed(error.localizedDescription)
        }
    }

    @MainActor
    private func shareSession() {
        let uv = session.averageUVIndex.formatted(.number.precision(.fractionLength(1)))
        let doseFraction = session.fractionOfMED.formatted(.percent.precision(.fractionLength(0)))
        let card = ShareCardView(content: ShareCardContent(
            eyebrow: String(localized: "Sessione completata"),
            headline: sessionDurationText,
            unit: String(localized: "di sole intelligente"),
            message: sessionInsight,
            metrics: [
                ShareCardMetric(icon: "sun.max.fill", value: uv, label: String(localized: "UV medio")),
                ShareCardMetric(icon: "gauge.with.needle", value: doseFraction, label: String(localized: "soglia")),
                ShareCardMetric(icon: "arrow.left.and.right", value: sideShareText, label: String(localized: "fronte / retro"))
            ],
            symbol: "checkmark.seal.fill"
        ))
        sharePayload = renderSharePayload(
            content: card,
            caption: String(localized: "Sessione Tanora completata: \(sessionDurationText), UV medio \(uv), \(doseFraction) della soglia UV. ☀️"),
            source: "session_summary"
        )
    }

    private var sessionDurationText: String {
        let seconds = Int(session.duration.rounded())
        if seconds < 60 {
            return String(localized: "\(seconds) s")
        }
        let minutes = Int((Double(seconds) / 60).rounded())
        if minutes >= 60 {
            return String(localized: "\(minutes / 60) h \(minutes % 60) min")
        }
        return String(localized: "\(minutes) min")
    }

    private var sideShareText: String {
        "\(session.frontExposureSeconds / 60) / \(session.backExposureSeconds / 60) min"
    }

    private func durationText(seconds: Int) -> String {
        if seconds < 60 {
            return String(localized: "\(seconds) s")
        }
        let minutes = seconds / 60
        if minutes >= 60 {
            return String(localized: "\(minutes / 60) h \(minutes % 60) min")
        }
        return String(localized: "\(minutes) min")
    }

    private var trackedSkinResponses: [SkinResponse] {
        [.comfortable, .warm, .tight, .red]
    }

    private var sideBalanceText: String {
        let difference = abs(session.frontExposureSeconds - session.backExposureSeconds)
        if session.frontExposureSeconds + session.backExposureSeconds == 0 {
            return String(localized: "Nessun lato tracciato: dalla prossima sessione usa il selettore fronte/retro.")
        }
        if difference >= 10 * 60 {
            return String(localized: "Sessione sbilanciata: la prossima volta parti dal lato meno esposto.")
        }
        if difference >= 5 * 60 {
            return String(localized: "Quasi uniforme: pochi minuti di differenza tra fronte e retro.")
        }
        return String(localized: "Ottimo equilibrio: fronte e retro sono rimasti vicini.")
    }

    private var sessionInsight: String {
        if session.fractionOfMED >= SafeExposure.recommendedLimitFractionOfMED {
            return String(localized: "Hai raggiunto la soglia UV: oggi basta sole diretto.")
        }
        if session.fractionOfMED >= 0.55 {
            return String(localized: "Sessione intensa ma ancora sotto soglia: utile per abbronzarti gradualmente, senza aggiungere altro sole oggi.")
        }
        if session.duration < Double(session.plannedDurationMinutes * 60) * 0.8 {
            return String(localized: "Sessione più breve dell'obiettivo: utile come esposizione leggera, ma il risultato sarà graduale.")
        }
        return String(localized: "Bella sessione: sei rimasto sotto la soglia UV.")
    }

    private var nextStepText: String {
        switch skinResponse {
        case .red:
            return String(localized: "Domani pausa dal sole diretto e idratazione: il rossore è un segnale da non ignorare.")
        case .tight:
            return String(localized: "La prossima volta riduci qualche minuto o aumenta SPF; stasera doposole.")
        case .warm:
            return String(localized: "Recupero leggero: acqua, ombra e prossima sessione nelle ore ideali.")
        case .comfortable, .notLogged:
            return sideBalanceText
        }
    }

    private func goalTitle(_ goal: SunExposureGoal) -> LocalizedStringKey {
        switch goal {
        case .vitaminD: return "Vitamina D"
        case .gradualTan: return "Abbronzatura graduale"
        case .lowRisk: return "Sessione leggera"
        }
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
}
