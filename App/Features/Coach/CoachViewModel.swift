import Foundation
import Observation
import SoleaCore

@MainActor
@Observable
final class CoachViewModel {
    private let maxMessageCharacters = 2_000
    private let maxMessagesPerRequest = 12
    private let maxTotalRequestCharacters = 8_000

    private(set) var messages: [CoachMessage] = []
    private(set) var isResponding = false
    private(set) var errorMessage: String?
    var draft = ""

    private let router = CoachRouter()
    private var streamTask: Task<Void, Never>?

    var isAvailable: Bool { router.hasAnyEngine }

    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isResponding
    }

    func send(context: CoachContext) {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard text.count <= maxMessageCharacters else {
            errorMessage = String(localized: "Messaggio troppo lungo: resta entro 2000 caratteri.")
            return
        }
        draft = ""
        errorMessage = nil
        messages.append(CoachMessage(role: .user, text: text))

        var assistant = CoachMessage(role: .assistant, text: "")
        messages.append(assistant)
        let assistantID = assistant.id
        isResponding = true

        streamTask = Task {
            do {
                for try await chunk in router.reply(to: conversationForRequest(), context: context) {
                    assistant.text += chunk
                    if let index = messages.firstIndex(where: { $0.id == assistantID }) {
                        messages[index] = assistant
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
                // Rimuove la bolla vuota dell'assistente se non è arrivato nulla.
                if assistant.text.isEmpty,
                   let index = messages.firstIndex(where: { $0.id == assistantID }) {
                    messages.remove(at: index)
                }
            }
            isResponding = false
        }
    }

    func cancel() {
        streamTask?.cancel()
        streamTask = nil
        isResponding = false
    }

    /// Invio solo la coda utile: niente placeholder e niente cronologie troppo costose.
    private func conversationForRequest() -> [CoachMessage] {
        let usableMessages = messages.filter { message in
            let text = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return !text.isEmpty && !(message.role == .assistant && message.text.isEmpty)
        }

        var selected: [CoachMessage] = []
        var totalCharacters = 0

        for message in usableMessages.reversed() {
            let nextTotal = totalCharacters + message.text.count
            guard selected.count < maxMessagesPerRequest,
                  nextTotal <= maxTotalRequestCharacters else {
                break
            }
            selected.append(message)
            totalCharacters = nextTotal
        }

        return selected.reversed()
    }
}
