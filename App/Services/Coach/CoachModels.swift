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

/// Stato sintetico dei motori disponibili, mostrato in chat per chiarire
/// quando il proxy cloud e' davvero configurato.
struct CoachAvailability: Equatable {
    let isOnDeviceAvailable: Bool
    let isCloudConfigured: Bool
    let isOnline: Bool

    var hasAnyEngine: Bool {
        isOnDeviceAvailable || isCloudConfigured
    }

    var systemImage: String {
        if isOnDeviceAvailable && isCloudConfigured {
            return "checkmark.seal.fill"
        }
        if isCloudConfigured {
            return isOnline ? "cloud.fill" : "wifi.slash"
        }
        if isOnDeviceAvailable {
            return "iphone.gen3"
        }
        return "exclamationmark.triangle.fill"
    }

    var title: String {
        if isOnDeviceAvailable && isCloudConfigured {
            return String(localized: "On-device + cloud pronti")
        }
        if isCloudConfigured {
            return String(localized: "Cloud Gemini configurato")
        }
        if isOnDeviceAvailable {
            return String(localized: "On-device attivo")
        }
        return String(localized: "Coach non configurato")
    }

    var detail: String {
        if isOnDeviceAvailable && isCloudConfigured {
            return String(localized: "Il router sceglie tra privato/offline e cloud per le domande più complesse.")
        }
        if isCloudConfigured {
            return isOnline
                ? String(localized: "Il proxy cloud è pronto; il modello locale non è disponibile su questo dispositivo.")
                : String(localized: "Il proxy cloud è configurato, ma serve connessione per usarlo.")
        }
        if isOnDeviceAvailable {
            return String(localized: "Funziona offline su questo dispositivo. Configura il proxy per Gemini quando vuoi abilitare il cloud.")
        }
        return String(localized: "Configura il proxy cloud o usa un dispositivo con modello on-device.")
    }
}

/// Contesto dell'utente passato al coach. Solo dati strettamente necessari —
/// niente foto, niente identificativi personali.
struct CoachContext {
    private static let maxSummaryCharacters = 1_100
    private static let maxDestinationCharacters = 80

    let phototype: Fitzpatrick
    let currentUVIndex: Double?
    let todaySessionCount: Int
    let todayMEDFraction: Double
    let weekSessionCount: Int
    let currentStreak: Int
    let recentSessions: [CoachSessionSnapshot]
    let nextVacationPlan: CoachVacationPlanSnapshot?

    /// Riassunto testuale per il prompt.
    func summary() -> String {
        var lines = ["Fototipo Fitzpatrick: \(phototype.romanNumeral)"]
        if let uv = currentUVIndex {
            lines.append("Indice UV attuale: \(Int(uv.rounded()))")
        } else {
            lines.append("Indice UV attuale: non disponibile")
        }
        lines.append("Sessioni di oggi: \(todaySessionCount)")
        lines.append("Dose MED stimata oggi: \(Self.percent(todayMEDFraction))")
        lines.append("Sessioni ultimi 7 giorni: \(weekSessionCount)")
        lines.append("Streak di giorni smart: \(currentStreak)")

        if !recentSessions.isEmpty {
            lines.append("Sessioni recenti:")
            for session in recentSessions.prefix(3) {
                lines.append("- \(session.summaryLine())")
            }
        }

        if let nextVacationPlan {
            lines.append("Prossimo piano vacanze: \(nextVacationPlan.summaryLine())")
        }

        let summary = lines.joined(separator: "\n")
        return String(summary.prefix(Self.maxSummaryCharacters))
    }

    private static func percent(_ value: Double) -> String {
        guard value.isFinite else { return "0%" }
        return "\(max(0, Int((value * 100).rounded())))%"
    }

    static func sanitizedDestinationName(_ value: String) -> String {
        let singleLine = value
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !singleLine.isEmpty else { return "destinazione non specificata" }
        return String(singleLine.prefix(maxDestinationCharacters))
    }
}

/// Riepilogo non identificativo di una sessione: niente note libere né foto.
struct CoachSessionSnapshot {
    let date: Date
    let exposureMinutes: Int
    let averageUVIndex: Double
    let spf: Double
    let fractionOfMED: Double?
    let skinResponse: SkinResponse

    func summaryLine() -> String {
        var parts = [
            date.formatted(date: .abbreviated, time: .omitted),
            "\(exposureMinutes) min",
            "UV medio \(Int(averageUVIndex.rounded()))",
            "SPF \(Int(spf.rounded()))"
        ]
        if let fractionOfMED {
            parts.append("dose \(Int((fractionOfMED * 100).rounded()))% MED")
        }
        if skinResponse != .notLogged {
            parts.append("pelle \(skinResponse.coachLabel)")
        }
        return parts.joined(separator: ", ")
    }
}

/// Riepilogo del prossimo piano vacanze; il nome destinazione e' l'unico testo
/// utente incluso perché serve al caso d'uso del planner.
struct CoachVacationPlanSnapshot {
    let destinationName: String
    let departureDate: Date
    let expectedUVIndex: Double
    let dayCount: Int
    let nextDayMinutes: Int?
    let nextDaySPF: Int?

    func summaryLine() -> String {
        let destination = CoachContext.sanitizedDestinationName(destinationName)
        var parts = [
            destination,
            "partenza \(departureDate.formatted(date: .abbreviated, time: .omitted))",
            "UV previsto \(Int(expectedUVIndex.rounded()))",
            "\(dayCount) giorni"
        ]
        if let nextDayMinutes, let nextDaySPF {
            parts.append("prossimo step \(nextDayMinutes) min SPF \(nextDaySPF)")
        }
        return parts.joined(separator: ", ")
    }
}

private extension SkinResponse {
    var coachLabel: String {
        switch self {
        case .notLogged:
            return "non registrata"
        case .comfortable:
            return "bene"
        case .warm:
            return "calda"
        case .tight:
            return "tira"
        case .red:
            return "rossa"
        }
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
