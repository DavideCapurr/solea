import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Coach basato sul modello on-device di Apple (Foundation Models, iOS 26+).
/// Gratis, privato, offline. Disponibile solo dietro availability check.
struct OnDeviceCoach: CoachEngine {
    /// `true` se il framework esiste e il modello di sistema è pronto all'uso.
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return SystemLanguageModel.default.availability == .available
        }
        #endif
        return false
    }

    func reply(to messages: [CoachMessage], context: CoachContext) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            #if canImport(FoundationModels)
            if #available(iOS 26, *), Self.isAvailable {
                let task = Task {
                    do {
                        let session = LanguageModelSession(instructions: Self.instructions)
                        let prompt = Self.prompt(messages: messages, context: context)
                        // Streaming dei "snapshot" cumulativi: inoltriamo solo il
                        // delta rispetto a quanto già emesso.
                        var emitted = ""
                        for try await partial in session.streamResponse(to: prompt) {
                            let full = partial.content
                            if full.count > emitted.count {
                                let delta = String(full.dropFirst(emitted.count))
                                emitted = full
                                continuation.yield(delta)
                            }
                        }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
                continuation.onTermination = { _ in task.cancel() }
                return
            }
            #endif
            continuation.finish(throwing: CoachError.onDeviceUnavailable)
        }
    }

    private static let instructions = """
    Sei il Coach Solare dell'app Solea. Aiuti a pianificare esposizioni più consapevoli e prudenti.
    Tono amichevole e conciso (max 3-4 frasi). Usi il contesto fornito (fototipo, UV, sessioni).
    Niente consigli medici: per dubbi sulla pelle rimanda a un dermatologo.
    """

    private static func prompt(messages: [CoachMessage], context: CoachContext) -> String {
        var parts = ["Contesto utente:\n\(context.summary())", ""]
        for message in messages {
            let speaker = message.role == .user ? "Utente" : "Coach"
            parts.append("\(speaker): \(message.text)")
        }
        parts.append("Coach:")
        return parts.joined(separator: "\n")
    }
}
