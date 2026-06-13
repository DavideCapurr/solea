import Foundation
import SoleaCore

/// Un messaggio nella chat del Coach.
struct CoachMessage: Identifiable, Equatable {
    enum Role: String {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    var text: String
}

/// Contesto dell'utente passato al coach. Solo dati strettamente necessari —
/// niente foto, niente identificativi personali.
struct CoachContext {
    let phototype: Fitzpatrick
    let currentUVIndex: Double?
    let todaySessionCount: Int
    let currentStreak: Int

    /// Riassunto testuale per il prompt.
    func summary() -> String {
        var lines = ["Fototipo Fitzpatrick: \(phototype.romanNumeral)"]
        if let uv = currentUVIndex {
            lines.append("Indice UV attuale: \(Int(uv.rounded()))")
        }
        lines.append("Sessioni di oggi: \(todaySessionCount)")
        lines.append("Streak di giorni smart: \(currentStreak)")
        return lines.joined(separator: "\n")
    }
}

enum CoachError: LocalizedError {
    case onDeviceUnavailable
    case network(String)
    case server(String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .onDeviceUnavailable:
            return String(localized: "Il modello on-device non è disponibile su questo dispositivo.")
        case .network(let message):
            return String(localized: "Problema di connessione: \(message)")
        case .server(let message):
            return message
        case .decoding:
            return String(localized: "Risposta del coach non leggibile.")
        }
    }
}

/// Interfaccia comune ai due motori (on-device e cloud).
protocol CoachEngine {
    /// Streaming della risposta come sequenza di frammenti di testo.
    func reply(to messages: [CoachMessage], context: CoachContext) -> AsyncThrowingStream<String, Error>
}
