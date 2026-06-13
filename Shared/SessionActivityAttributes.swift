import Foundation
import ActivityKit

/// Attributi della Live Activity della sessione, condivisi tra app ed estensione widget.
struct SessionActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var elapsedSeconds: Int
        /// Frazione della MED già assorbita (0...1+).
        var doseFraction: Double
        var currentUVIndex: Double
        /// Secondi di esposizione sicura rimanenti; `nil` = illimitato (UV trascurabile).
        var remainingSafeSeconds: Double?
    }

    /// Numero romano del fototipo (es. "III"), solo per display.
    var phototypeRoman: String
    var startedAt: Date
}
