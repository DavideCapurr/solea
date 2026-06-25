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
    private(set) var goalRawValue: String?
    private(set) var frontExposureSeconds: Int?
    private(set) var backExposureSeconds: Int?
    private(set) var plannedDurationMinutes: Int?
    private(set) var exposureSeconds: Int?
    private(set) var pausedSeconds: Int?
    private(set) var skinResponseRawValue: String?
    private(set) var note: String?

    init(
        startedAt: Date,
        endedAt: Date,
        spf: Double,
        exposedZones: ExposedZones,
        averageUVIndex: Double,
        uvDose: Double,
        vitaminDIU: Double,
        phototype: Fitzpatrick,
        goal: SunExposureGoal = .gradualTan,
        frontExposureSeconds: Int = 0,
        backExposureSeconds: Int = 0,
        plannedDurationMinutes: Int = 20,
        exposureSeconds: Int? = nil,
        pausedSeconds: Int = 0,
        skinResponse: SkinResponse = .notLogged,
        note: String = ""
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.spf = spf
        self.exposedZonesRawValue = exposedZones.rawValue
        self.averageUVIndex = averageUVIndex
        self.uvDose = uvDose
        self.vitaminDIU = vitaminDIU
        self.phototypeRawValue = phototype.rawValue
        self.goalRawValue = goal.rawValue
        self.frontExposureSeconds = frontExposureSeconds
        self.backExposureSeconds = backExposureSeconds
        self.plannedDurationMinutes = plannedDurationMinutes
        self.exposureSeconds = exposureSeconds
        self.pausedSeconds = pausedSeconds
        self.skinResponseRawValue = skinResponse.rawValue
        self.note = note
    }

    var exposedZones: ExposedZones {
        ExposedZones(rawValue: exposedZonesRawValue)
    }

    var duration: TimeInterval {
        if let exposureSeconds {
            return TimeInterval(exposureSeconds)
        }
        return endedAt.timeIntervalSince(startedAt)
    }

    var totalDuration: TimeInterval {
        return endedAt.timeIntervalSince(startedAt)
    }

    var goal: SunExposureGoal {
        guard let goalRawValue else { return .gradualTan }
        return SunExposureGoal(rawValue: goalRawValue) ?? .gradualTan
    }

    var frontSeconds: Int {
        frontExposureSeconds ?? 0
    }

    var backSeconds: Int {
        backExposureSeconds ?? 0
    }

    var skinResponse: SkinResponse {
        guard let skinResponseRawValue else { return .notLogged }
        return SkinResponse(rawValue: skinResponseRawValue) ?? .notLogged
    }

    var plannedMinutes: Int {
        plannedDurationMinutes ?? 0
    }

    var pauseSeconds: Int {
        pausedSeconds ?? 0
    }

    var noteText: String {
        note ?? ""
    }

    func updateReflection(skinResponse: SkinResponse, note: String) {
        self.skinResponseRawValue = skinResponse.rawValue
        self.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Frazione della MED del fototipo registrato al momento della sessione.
    var fractionOfMED: Double? {
        guard let phototype = Fitzpatrick(rawValue: phototypeRawValue) else { return nil }
        return uvDose / phototype.med
    }
}
