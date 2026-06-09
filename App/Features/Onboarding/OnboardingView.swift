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
    @State private var step: Step = .welcome
    @State private var answers: [Int: Int] = [:] // id domanda → punteggio
    @State private var saveErrorMessage: String?

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
        }
    }

    private var welcome: some View {
        VStack(spacing: 24) {
            Spacer()
            heroImage
            Text("Benvenuto in Solea")
                .font(.largeTitle.bold())
            Text("Abbronzati al meglio, senza scottarti: tempi di esposizione su misura per la tua pelle e l'UV reale della tua zona.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
            Text("Solea fornisce stime informative, non consigli medici. In caso di dubbi sulla tua pelle consulta un dermatologo.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                step = .question(0)
            } label: {
                Text("Scopri il tuo fototipo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
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
            ProgressView(value: Double(index), total: Double(FitzpatrickQuiz.questions.count))
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
        VStack(spacing: 24) {
            Spacer()
            Text("Il tuo fototipo")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(phototype.romanNumeral)
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)
            Text(LocalizedStringKey(phototype.summaryKey))
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                save(phototype: phototype, score: score)
            } label: {
                Text("Inizia")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
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
