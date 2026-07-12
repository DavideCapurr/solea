import SwiftUI
import SwiftData
import UIKit
import SoleaCore

struct OnboardingView: View {
    private enum Step: Equatable {
        case welcome
        case question(Int)
        case result(Fitzpatrick, score: Int)
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(SoleaPlusStore.self) private var plusStore
    @State private var step: Step = .welcome
    @State private var answers: [Int: Int] = [:] // id domanda → punteggio
    @State private var saveErrorMessage: String?
    @State private var sharePayload: SharePayload?
    @State private var showPlusPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .welcome:
                    welcome
                case .question(let index):
                    questionView(index: index)
                case .result(let phototype, let score):
                    resultView(phototype: phototype, score: score)
                }
            }
            .animation(.default, value: step)
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
            .sheet(item: $sharePayload) { payload in
                ShareSheet(payload: payload)
            }
            .sheet(isPresented: $showPlusPaywall) {
                SoleaPlusPaywallView(source: "onboarding_share")
            }
        }
    }

    private var welcome: some View {
        ScrollView {
            VStack(spacing: 22) {
                heroImage
                    .padding(.top, 12)

                Text("IL SOLE CAMBIA OGNI GIORNO")
                    .font(.caption.bold())
                    .tracking(1.1)
                    .foregroundStyle(.orange)

                Text("Il tuo tempo al sole,\nin un check.")
                    .font(.largeTitle.weight(.black))
                    .fontDesign(.rounded)
                    .multilineTextAlignment(.center)

                Text("Incrociamo fototipo e UV reale per darti una stima quotidiana semplice, personale e prudente.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    welcomeChip("UV reale", icon: "sun.max.fill")
                    welcomeChip("6 domande", icon: "checklist")
                    welcomeChip("Dati locali", icon: "lock.fill")
                }

                Button {
                    step = .question(0)
                } label: {
                    Label("Fai il mio Tan Check", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)

                Text("Tanora fornisce stime informative, non consigli medici. In caso di dubbi sulla tua pelle consulta un dermatologo.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                ScientificSourcesLink()
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.12), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        )
    }

    private func welcomeChip(_ title: LocalizedStringKey, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption2.bold())
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.orange.opacity(0.10), in: Capsule())
    }

    @ViewBuilder
    private var heroImage: some View {
        if UIImage(named: "OnboardingHero") != nil {
            Image("OnboardingHero")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 220)
        } else {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 88))
                .foregroundStyle(.orange)
        }
    }

    private func questionView(index: Int) -> some View {
        let question = FitzpatrickQuiz.questions[index]
        return VStack(alignment: .leading, spacing: 16) {
            ProgressView(value: Double(index + 1), total: Double(FitzpatrickQuiz.questions.count))
                .tint(.orange)
            Text(LocalizedStringKey(question.text))
                .font(.title2.bold())

            ForEach(question.options) { option in
                Button {
                    select(option: option, for: question)
                } label: {
                    HStack {
                        Text(LocalizedStringKey(option.text))
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if answers[question.id] == option.score {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .tint(answers[question.id] == option.score ? .accentColor : .secondary)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Domanda \(index + 1) di \(FitzpatrickQuiz.questions.count)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if index > 0 {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Indietro") { step = .question(index - 1) }
                }
            }
        }
    }

    private func select(option: QuizOption, for question: QuizQuestion) {
        answers[question.id] = option.score
        let nextIndex = question.id + 1
        if nextIndex < FitzpatrickQuiz.questions.count {
            step = .question(nextIndex)
        } else {
            let score = answers.values.reduce(0, +)
            step = .result(FitzpatrickQuiz.phototype(totalScore: score), score: score)
        }
    }

    private func resultView(phototype: Fitzpatrick, score: Int) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 14) {
                    Text("IL TUO PROFILO SOLARE")
                        .font(.caption.bold())
                        .tracking(1.2)
                        .foregroundStyle(.black.opacity(0.62))

                    Text(phototype.romanNumeral)
                        .font(.system(size: 116, weight: .black, design: .rounded))
                        .foregroundStyle(.black.opacity(0.84))

                    Text("Fototipo \(phototype.romanNumeral)")
                        .font(.title2.bold())

                    Text(LocalizedStringKey(phototype.summaryKey))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.black.opacity(0.68))

                    Label("Ora puoi ricevere il tuo check quotidiano", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.black.opacity(0.72))
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [.yellow.opacity(0.72), .orange.opacity(0.42)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 28)
                )

                Button {
                    if plusStore.hasPlus {
                        sharePhototype(phototype)
                    } else {
                        showPlusPaywall = true
                    }
                } label: {
                    Label("Condividi il mio fototipo", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    save(phototype: phototype, score: score)
                } label: {
                    Label("Vedi il piano di oggi", systemImage: "sun.max.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)

                Text("La condivisione non include posizione o altri dati personali.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }

    @MainActor
    private func sharePhototype(_ phototype: Fitzpatrick) {
        let summary = String(localized: String.LocalizationValue(phototype.summaryKey))
        let card = ShareCardView(content: ShareCardContent(
            eyebrow: String(localized: "Il mio profilo solare"),
            headline: phototype.romanNumeral,
            unit: String(localized: "fototipo"),
            message: summary,
            metrics: [
                ShareCardMetric(icon: "checklist", value: "6", label: String(localized: "domande")),
                ShareCardMetric(icon: "gauge.with.needle", value: "\(Int(phototype.med))", label: "MED J/m²"),
                ShareCardMetric(icon: "lock.fill", value: String(localized: "Locale"), label: String(localized: "privacy"))
            ],
            symbol: "sun.max.fill"
        ))
        sharePayload = renderSharePayload(
            content: card,
            caption: String(localized: "Ho scoperto il mio fototipo con Tanora: \(phototype.romanNumeral). Ora posso fare il mio check solare quotidiano. ☀️"),
            source: "onboarding_phototype"
        )
    }

    private func save(phototype: Fitzpatrick, score: Int) {
        do {
            try modelContext.delete(model: UserProfile.self)
            modelContext.insert(UserProfile(phototype: phototype, quizScore: score))
            try modelContext.save()
        } catch {
            // L'errore viene mostrato all'utente, non assorbito: senza profilo
            // salvato si resta nell'onboarding.
            saveErrorMessage = error.localizedDescription
        }
    }
}
