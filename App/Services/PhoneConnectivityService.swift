import Foundation
import Observation
import SoleaCore
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

/// Sincronizza il fototipo del profilo verso l'Apple Watch via WatchConnectivity.
///
/// Usa `updateApplicationContext`, che trasferisce sempre e solo l'ultimo stato
/// noto e lo consegna appena il Watch è raggiungibile: ideale per un dato di
/// configurazione come il fototipo. Gli errori non vengono mai silenziati —
/// attivazione e invii falliti finiscono in `lastError`, mentre uno stato
/// "in attesa di attivazione" non è un errore (verrà inviato al completamento).
@MainActor
@Observable
final class PhoneConnectivityService: NSObject {
    /// Chiave dell'application context: deve combaciare con quella letta dal
    /// Watch in `WatchProfileSync`.
    static let phototypeKey = "phototypeRawValue"

    private(set) var lastError: String?
    private var pendingPhototypeRawValue: Int?

    /// Da chiamare una volta all'avvio dell'app.
    func activate() {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        #endif
    }

    /// Richiede l'invio del fototipo al Watch. Se la sessione non è ancora
    /// attiva il valore resta in coda e parte appena l'attivazione completa.
    func sync(phototype: Fitzpatrick) {
        pendingPhototypeRawValue = phototype.rawValue
        flush()
    }

    private func flush() {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported(), let rawValue = pendingPhototypeRawValue else { return }
        let session = WCSession.default
        guard session.activationState == .activated else {
            // In attesa: non è un fallimento, l'invio avverrà a attivazione completa.
            return
        }
        do {
            try session.updateApplicationContext([Self.phototypeKey: rawValue])
            pendingPhototypeRawValue = nil
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        #endif
    }
}

#if canImport(WatchConnectivity)
extension PhoneConnectivityService: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                self.lastError = error.localizedDescription
            } else {
                self.flush()
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Riattiva per agganciarsi all'eventuale nuovo Watch abbinato.
        session.activate()
    }
}
#endif
