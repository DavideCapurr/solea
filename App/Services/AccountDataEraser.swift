import Foundation
import SwiftData
import GameKit
import UserNotifications

/// Esegue l'eliminazione completa dei dati locali di Abbronzo, richiesta dalla
/// linea guida App Store 5.1.1(v) per le app che permettono la creazione di un
/// profilo/account.
///
/// Abbronzo non ha account su server: tutti i dati vivono sul dispositivo, quindi
/// "elimina account" coincide con un wipe completo che riporta l'app
/// all'onboarding (la `RootView` torna all'onboarding quando non c'è più un
/// `UserProfile`).
enum AccountDataEraser {
    /// Chiavi `@AppStorage`/`UserDefaults` scritte dall'app, da azzerare.
    static let userDefaultsKeys = [
        "currentSkinResponse",
        "goldenHourRemindersEnabled",
        "watch.phototype",
        "watch.soleaPlusActive",
        "coach.anonymousUserID"
    ]

    /// Cancella profilo, sessioni, piani, foto del diario, preferenze locali e
    /// promemoria in sospeso, e azzera i traguardi Game Center.
    @MainActor
    static func eraseAllData(in context: ModelContext) throws {
        // 1. Dati SwiftData (profilo, sessioni, piani, foto del diario).
        try context.delete(model: UserProfile.self)
        try context.delete(model: TanSession.self)
        try context.delete(model: VacationPlan.self)
        try context.delete(model: TanPhoto.self)
        try context.save()

        // 2. Preferenze locali e id anonimo del coach.
        let defaults = UserDefaults.standard
        for key in userDefaultsKeys {
            defaults.removeObject(forKey: key)
        }

        // 3. Promemoria locali (in sospeso e già consegnati).
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()

        // 4. Traguardi Game Center: best-effort, non deve bloccare l'eliminazione
        //    dei dati locali se l'utente non è autenticato o la rete non risponde.
        if GKLocalPlayer.local.isAuthenticated {
            GKAchievement.resetAchievements(completionHandler: nil)
        }
    }
}
