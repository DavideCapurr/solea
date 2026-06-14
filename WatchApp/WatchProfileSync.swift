import Foundation
import Observation
import SoleaCore
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

/// Riceve il fototipo dall'iPhone via WatchConnectivity e lo rende disponibile
/// al Watch. Scrive nello stesso `UserDefaults` (`watch.phototype`) usato dal
/// picker locale: così, finché non arriva il primo contesto, il Watch resta
/// usabile con la scelta manuale (default legittimo, non un errore mascherato),
/// e quando l'iPhone sincronizza il picker si aggiorna da solo.
@MainActor
@Observable
final class WatchProfileSync: NSObject {
    /// Chiave dell'application context: deve combaciare con quella scritta
    /// dall'iPhone in `PhoneConnectivityService`.
    static let phototypeKey = "phototypeRawValue"
    /// Chiave `UserDefaults` condivisa con `@AppStorage("watch.phototype")`.
    static let defaultsKey = "watch.phototype"

    /// Esposto per eventuale diagnostica in UI: un'attivazione fallita non va
    /// nascosta.
    private(set) var lastError: String?

    func activate() {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        // Applica subito l'eventuale contesto già ricevuto in precedenza.
        apply(session.receivedApplicationContext)
        #endif
    }

    private func apply(_ context: [String: Any]) {
        guard
            let rawValue = context[Self.phototypeKey] as? Int,
            Fitzpatrick(rawValue: rawValue) != nil
        else { return }
        UserDefaults.standard.set(rawValue, forKey: Self.defaultsKey)
    }
}

#if canImport(WatchConnectivity)
extension WatchProfileSync: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        let context = session.receivedApplicationContext
        Task { @MainActor in
            if let error {
                self.lastError = error.localizedDescription
            } else {
                self.lastError = nil
                self.apply(context)
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in self.apply(applicationContext) }
    }
}
#endif
