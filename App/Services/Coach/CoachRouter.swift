import Foundation
import Network

/// Configurazione del coach: dove vive il proxy e l'id anonimo dell'utente.
enum CoachConfiguration {
    /// Imposta qui l'URL del tuo deploy Cloudflare (vedi server/coach-proxy).
    /// Finché è nil, il coach funziona solo on-device.
    static let proxyURL: URL? = nil

    /// Identificativo anonimo e stabile (non personale), per il rate limit.
    static var anonymousUserID: String {
        let key = "coach.anonymousUserID"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }
}

/// Sceglie il motore giusto (on-device vs cloud) e gestisce i fallback.
///
/// Regole:
/// - Richiesta complessa o conversazione lunga → cloud (più capace), se disponibile.
/// - Offline → on-device, se disponibile.
/// - Se il motore scelto fallisce, si tenta l'altro prima di arrendersi.
@MainActor
final class CoachRouter {
    private let monitor = NWPathMonitor()
    private var isOnline = true

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in self?.isOnline = path.status == .satisfied }
        }
        monitor.start(queue: DispatchQueue(label: "coach.network.monitor"))
    }

    deinit {
        monitor.cancel()
    }

    private var cloud: CloudCoach? {
        guard let url = CoachConfiguration.proxyURL else { return nil }
        return CloudCoach(endpoint: url, userId: CoachConfiguration.anonymousUserID)
    }

    /// True se almeno un motore è utilizzabile.
    var hasAnyEngine: Bool {
        OnDeviceCoach.isAvailable || cloud != nil
    }

    func reply(
        to messages: [CoachMessage],
        context: CoachContext
    ) -> AsyncThrowingStream<String, Error> {
        let preferCloud = isOnline && shouldUseCloud(for: messages)
        let primary = engine(cloud: preferCloud)
        let fallback = engine(cloud: !preferCloud)

        return AsyncThrowingStream { continuation in
            let task = Task {
                if let primary, await self.pump(primary, messages, context, into: continuation) {
                    continuation.finish()
                    return
                }
                // Il primario non c'è o ha fallito senza emettere nulla: prova l'altro.
                if let fallback, await self.pump(fallback, messages, context, into: continuation) {
                    continuation.finish()
                    return
                }
                continuation.finish(throwing: CoachError.onDeviceUnavailable)
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Inoltra lo stream del motore; ritorna `true` se ha prodotto almeno un
    /// frammento (successo), `false` se è fallito senza output (→ fallback).
    /// Se fallisce *dopo* aver emesso, propaga l'errore: non si fa il fallback
    /// a metà risposta per non mescolare due output.
    private func pump(
        _ engine: CoachEngine,
        _ messages: [CoachMessage],
        _ context: CoachContext,
        into continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async -> Bool {
        var emittedSomething = false
        do {
            for try await chunk in engine.reply(to: messages, context: context) {
                emittedSomething = true
                continuation.yield(chunk)
            }
            return true
        } catch {
            if emittedSomething {
                continuation.finish(throwing: error)
                return true
            }
            return false
        }
    }

    private func engine(cloud: Bool) -> CoachEngine? {
        if cloud {
            return self.cloud
        }
        return OnDeviceCoach.isAvailable ? OnDeviceCoach() : nil
    }

    /// Euristica di complessità: messaggi lunghi o conversazioni con storia
    /// beneficiano del modello cloud più capace.
    private func shouldUseCloud(for messages: [CoachMessage]) -> Bool {
        guard cloud != nil else { return false }
        let lastUserLength = messages.last(where: { $0.role == .user })?.text.count ?? 0
        return messages.count > 2 || lastUserLength > 140
    }
}
