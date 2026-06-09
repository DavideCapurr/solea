import Foundation

public struct QuizOption: Identifiable, Hashable, Sendable {
    /// L'id coincide con il punteggio (0–4), come nel questionario Fitzpatrick classico.
    public let id: Int
    /// Testo in italiano (lingua sorgente): usato anche come chiave di localizzazione.
    public let text: String

    public var score: Int { id }
}

public struct QuizQuestion: Identifiable, Hashable, Sendable {
    public let id: Int
    public let text: String
    public let options: [QuizOption]
}

/// Quiz per determinare il fototipo di Fitzpatrick: 6 domande con punteggio 0–4,
/// totale 0–24, mappato sui sei fototipi.
public enum FitzpatrickQuiz {
    public static let questions: [QuizQuestion] = [
        QuizQuestion(id: 0, text: "Di che colore sono i tuoi occhi?", options: [
            QuizOption(id: 0, text: "Azzurri o grigi"),
            QuizOption(id: 1, text: "Verdi"),
            QuizOption(id: 2, text: "Nocciola"),
            QuizOption(id: 3, text: "Marrone scuro"),
            QuizOption(id: 4, text: "Quasi neri"),
        ]),
        QuizQuestion(id: 1, text: "Qual è il colore naturale dei tuoi capelli?", options: [
            QuizOption(id: 0, text: "Rossi"),
            QuizOption(id: 1, text: "Biondi"),
            QuizOption(id: 2, text: "Castano chiaro"),
            QuizOption(id: 3, text: "Castano scuro"),
            QuizOption(id: 4, text: "Neri"),
        ]),
        QuizQuestion(id: 2, text: "Com'è la tua pelle dove non prende mai il sole?", options: [
            QuizOption(id: 0, text: "Molto chiara, lattea"),
            QuizOption(id: 1, text: "Chiara"),
            QuizOption(id: 2, text: "Chiara con sfumatura beige"),
            QuizOption(id: 3, text: "Olivastra"),
            QuizOption(id: 4, text: "Scura"),
        ]),
        QuizQuestion(id: 3, text: "Quante lentiggini hai sulle zone non esposte?", options: [
            QuizOption(id: 0, text: "Moltissime"),
            QuizOption(id: 1, text: "Parecchie"),
            QuizOption(id: 2, text: "Alcune"),
            QuizOption(id: 3, text: "Rare"),
            QuizOption(id: 4, text: "Nessuna"),
        ]),
        QuizQuestion(id: 4, text: "Come reagisce la tua pelle al sole prolungato senza protezione?", options: [
            QuizOption(id: 0, text: "Mi scotto sempre, non mi abbronzo mai"),
            QuizOption(id: 1, text: "Mi scotto facilmente, mi abbronzo poco"),
            QuizOption(id: 2, text: "A volte mi scotto, poi mi abbronzo"),
            QuizOption(id: 3, text: "Raramente mi scotto, mi abbronzo bene"),
            QuizOption(id: 4, text: "Non mi scotto quasi mai"),
        ]),
        QuizQuestion(id: 5, text: "Che grado di abbronzatura raggiungi?", options: [
            QuizOption(id: 0, text: "Nessuna"),
            QuizOption(id: 1, text: "Leggera"),
            QuizOption(id: 2, text: "Media"),
            QuizOption(id: 3, text: "Intensa"),
            QuizOption(id: 4, text: "La mia pelle è naturalmente scura"),
        ]),
    ]

    public static var maximumScore: Int {
        questions.reduce(0) { $0 + ($1.options.map(\.score).max() ?? 0) }
    }

    public static func phototype(totalScore: Int) -> Fitzpatrick {
        switch totalScore {
        case ..<4: return .typeI
        case 4..<8: return .typeII
        case 8..<13: return .typeIII
        case 13..<17: return .typeIV
        case 17..<21: return .typeV
        default: return .typeVI
        }
    }
}
