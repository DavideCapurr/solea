import Foundation
import SwiftData
import SoleaCore

/// Una sessione di abbronzatura completata. La sessione attiva vive in memoria
/// nel `SessionManager` e viene persistita solo alla chiusura.
@Model
final class TanSession {
    private(set) var startedAt: Date
    private(set) var endedAt: Date
    private(set) var spf: Double
    private(set) var exposedZonesRawValue: Int
    private(set) var averageUVIndex: Double
    /// Dose eritemale effettiva sulla pelle (J/m², già attenuata dall'SPF).
    private(set) var uvDose: Double
    private(set) var vitaminDIU: Double
    private(set) var phototypeRawValue: Int

    init(
        startedAt: Date,
        endedAt: Date,
        spf: Double,
        exposedZones: ExposedZones,
        averageUVIndex: Double,
        uvDose: Double,
        vitaminDIU: Double,
        phototype: Fitzpatrick
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.spf = spf
        self.exposedZonesRawValue = exposedZones.rawValue
        self.averageUVIndex = averageUVIndex
        self.uvDose = uvDose
        self.vitaminDIU = vitaminDIU
        self.phototypeRawValue = phototype.rawValue
    }

    var exposedZones: ExposedZones {
        ExposedZones(rawValue: exposedZonesRawValue)
    }

    var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }

    /// Frazione della MED del fototipo registrato al momento della sessione.
    var fractionOfMED: Double? {
        guard let phototype = Fitzpatrick(rawValue: phototypeRawValue) else { return nil }
        return uvDose / phototype.med
    }
}
