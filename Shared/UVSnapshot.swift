import Foundation
import SoleaCore

/// Istantanea dei dati UV che l'app scrive nell'App Group per i widget.
/// Il widget non interroga WeatherKit: mostra l'ultimo dato dell'app e, se è
/// troppo vecchio, lo dichiara invece di fingere un valore aggiornato.
struct UVSnapshot: Codable {
    let currentUVIndex: Double
    let safeMinutesBareSkin: Double
    let burnRiskRawValue: String
    let phototypeRawValue: Int
    let updatedAt: Date

    /// Oltre quest'età il widget mostra lo stato "dati non aggiornati".
    static let maxAge: TimeInterval = 90 * 60

    var isStale: Bool {
        Date.now.timeIntervalSince(updatedAt) > Self.maxAge
    }
}

enum SharedStoreError: LocalizedError {
    case appGroupUnavailable
    case encoding(Error)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            return String(localized: "App Group non disponibile: verifica la configurazione di firma del progetto.")
        case .encoding(let error), .decoding(let error):
            return error.localizedDescription
        }
    }
}

/// Lettura/scrittura della snapshot condivisa tramite App Group.
enum SharedStore {
    static let appGroupID = "group.com.davidecapurro.solea"
    private static let snapshotKey = "uvSnapshot"

    static func save(_ snapshot: UVSnapshot) throws {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            throw SharedStoreError.appGroupUnavailable
        }
        do {
            defaults.set(try JSONEncoder().encode(snapshot), forKey: snapshotKey)
        } catch {
            throw SharedStoreError.encoding(error)
        }
    }

    /// `nil` se non è mai stata scritta una snapshot.
    static func loadSnapshot() throws -> UVSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            throw SharedStoreError.appGroupUnavailable
        }
        guard let data = defaults.data(forKey: snapshotKey) else { return nil }
        do {
            return try JSONDecoder().decode(UVSnapshot.self, from: data)
        } catch {
            throw SharedStoreError.decoding(error)
        }
    }
}
