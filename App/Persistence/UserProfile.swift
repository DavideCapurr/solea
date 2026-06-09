import Foundation
import SwiftData
import SoleaCore

@Model
final class UserProfile {
    /// Raw value del fototipo Fitzpatrick (1–6). Scritto solo tramite `init`,
    /// quindi valido per costruzione; se lo store contenesse un valore corrotto,
    /// `phototype` torna nil e la UI rimanda all'onboarding invece di inventare
    /// un fototipo di ripiego.
    private(set) var phototypeRawValue: Int
    private(set) var quizScore: Int
    private(set) var createdAt: Date

    init(phototype: Fitzpatrick, quizScore: Int, createdAt: Date = .now) {
        self.phototypeRawValue = phototype.rawValue
        self.quizScore = quizScore
        self.createdAt = createdAt
    }

    var phototype: Fitzpatrick? {
        Fitzpatrick(rawValue: phototypeRawValue)
    }
}
