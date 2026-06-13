import Foundation
import Observation
import SoleaCore

@MainActor
@Observable
final class CoachViewModel {
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

    /// Esclude l'ultima bolla (placeholder vuoto dell'assistente) dalla richiesta.
    private func conversationForRequest() -> [CoachMessage] {
        messages.filter { !($0.role == .assistant && $0.text.isEmpty) }
    }
}
