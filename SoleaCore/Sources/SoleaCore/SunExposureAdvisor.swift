import Foundation

public enum SunExposureGoal: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case vitaminD
    case gradualTan
    case lowRisk

    public var id: String { rawValue }
}

public struct SunExposureRecommendation: Equatable, Sendable {
    public let goal: SunExposureGoal
    /// Minuti consigliati di esposizione diretta all'UV attuale.
    public let minutes: Double
    /// SPF suggerito per la sessione e per continuare la giornata.
    public let suggestedSPF: Int
    public let zones: ExposedZones
    public let estimatedVitaminDIU: Double
    public let effectiveDoseJoulesPerSquareMeter: Double
    public let remainingSafeDoseJoulesPerSquareMeter: Double
}

public enum SunExposureAdvisorError: Error, Equatable {
    case invalidUVIndex(Double)
    case invalidDoseAlreadyToday(Double)
}

/// Consiglia un tempo pratico al sole in base a un obiettivo, restando entro la
/// dose prudente usata dal resto dell'app.
public enum SunExposureAdvisor {
    public static let targetVitaminDIU = 800.0
    public static let vitaminDMaximumFractionOfMED = 0.35
    public static let gradualTanFractionOfMED = 0.55
    public static let lowRiskFractionOfMED = 0.30

    public static func recommendedGoal(
        phototype: Fitzpatrick,
        uvIndex: Double,
        doseAlreadyToday: Double = 0,
        skinResponse: SkinResponse = .notLogged
    ) throws -> SunExposureGoal {
        guard uvIndex >= 0, uvIndex.isFinite else {
            throw SunExposureAdvisorError.invalidUVIndex(uvIndex)
        }
        guard doseAlreadyToday >= 0, doseAlreadyToday.isFinite else {
            throw SunExposureAdvisorError.invalidDoseAlreadyToday(doseAlreadyToday)
        }

        switch skinResponse {
        case .red, .tight, .warm:
            return .lowRisk
        case .comfortable, .notLogged:
            break
        }

        let safeDoseLimit = SafeExposure.recommendedDoseLimit(phototype: phototype)
        let usedSafeDoseFraction = safeDoseLimit > 0 ? doseAlreadyToday / safeDoseLimit : 1

        if doseAlreadyToday >= safeDoseLimit || usedSafeDoseFraction >= 0.65 {
            return .lowRisk
        }
        if uvIndex <= SafeExposure.negligibleUVIndex {
            return .lowRisk
        }
        if uvIndex < 3 {
            return .vitaminD
        }
        if uvIndex >= 8 {
            return .lowRisk
        }
        if uvIndex >= 6, phototype.rawValue <= Fitzpatrick.typeIII.rawValue {
            return .lowRisk
        }
        return .gradualTan
    }

    public static func recommendedPlan(
        phototype: Fitzpatrick,
        uvIndex: Double,
        doseAlreadyToday: Double = 0,
        skinResponse: SkinResponse = .notLogged
    ) throws -> SunExposureRecommendation {
        let goal = try recommendedGoal(
            phototype: phototype,
            uvIndex: uvIndex,
            doseAlreadyToday: doseAlreadyToday,
            skinResponse: skinResponse
        )
        return try recommendation(
            phototype: phototype,
            uvIndex: uvIndex,
            goal: goal,
            doseAlreadyToday: doseAlreadyToday,
            skinResponse: skinResponse
        )
    }

    public static func recommendation(
        phototype: Fitzpatrick,
        uvIndex: Double,
        goal: SunExposureGoal,
        doseAlreadyToday: Double = 0,
        skinResponse: SkinResponse = .notLogged
    ) throws -> SunExposureRecommendation {
        guard uvIndex >= 0, uvIndex.isFinite else {
            throw SunExposureAdvisorError.invalidUVIndex(uvIndex)
        }
        guard doseAlreadyToday >= 0, doseAlreadyToday.isFinite else {
            throw SunExposureAdvisorError.invalidDoseAlreadyToday(doseAlreadyToday)
        }

        let zones = defaultZones(for: goal)
        let suggestedSPF = suggestedSPF(for: goal, phototype: phototype, uvIndex: uvIndex)
        let safeDoseLimit = SafeExposure.recommendedDoseLimit(phototype: phototype)
        let remainingSafeDose = max(0, safeDoseLimit - doseAlreadyToday)

        if shouldAvoidDirectSun(skinResponse) {
            return SunExposureRecommendation(
                goal: goal,
                minutes: 0,
                suggestedSPF: suggestedSPF,
                zones: zones,
                estimatedVitaminDIU: 0,
                effectiveDoseJoulesPerSquareMeter: 0,
                remainingSafeDoseJoulesPerSquareMeter: remainingSafeDose
            )
        }

        guard uvIndex > SafeExposure.negligibleUVIndex else {
            return SunExposureRecommendation(
                goal: goal,
                minutes: .infinity,
                suggestedSPF: suggestedSPF,
                zones: zones,
                estimatedVitaminDIU: 0,
                effectiveDoseJoulesPerSquareMeter: 0,
                remainingSafeDoseJoulesPerSquareMeter: remainingSafeDose
            )
        }

        let targetDose = min(
            adjustedTargetDose(for: goal, phototype: phototype, zones: zones, skinResponse: skinResponse),
            safeDoseLimit
        )
        let remainingGoalDose = max(0, targetDose - doseAlreadyToday)
        let usableDose = min(remainingGoalDose, remainingSafeDose)
        guard usableDose > 0 else {
            return SunExposureRecommendation(
                goal: goal,
                minutes: 0,
                suggestedSPF: suggestedSPF,
                zones: zones,
                estimatedVitaminDIU: 0,
                effectiveDoseJoulesPerSquareMeter: 0,
                remainingSafeDoseJoulesPerSquareMeter: remainingSafeDose
            )
        }

        let dosePerMinute = uvIndex * SafeExposure.wattsPerUVIndexUnit * 60
        let uncappedMinutes = usableDose / dosePerMinute
        let minutes = min(uncappedMinutes, maximumMinutes(for: goal))
        let effectiveDose = min(minutes * dosePerMinute, remainingSafeDose)
        let vitaminDIU = VitaminD.estimatedIU(
            effectiveDoseJoulesPerSquareMeter: effectiveDose,
            phototype: phototype,
            zones: zones
        )

        return SunExposureRecommendation(
            goal: goal,
            minutes: minutes,
            suggestedSPF: suggestedSPF,
            zones: zones,
            estimatedVitaminDIU: vitaminDIU,
            effectiveDoseJoulesPerSquareMeter: effectiveDose,
            remainingSafeDoseJoulesPerSquareMeter: remainingSafeDose
        )
    }

    private static func shouldAvoidDirectSun(_ skinResponse: SkinResponse) -> Bool {
        switch skinResponse {
        case .red, .tight:
            return true
        case .warm, .comfortable, .notLogged:
            return false
        }
    }

    private static func adjustedTargetDose(
        for goal: SunExposureGoal,
        phototype: Fitzpatrick,
        zones: ExposedZones,
        skinResponse: SkinResponse
    ) -> Double {
        let baseDose = targetDose(for: goal, phototype: phototype, zones: zones)
        guard skinResponse == .warm else { return baseDose }
        return min(baseDose, phototype.med * lowRiskFractionOfMED)
    }

    public static func defaultZones(for goal: SunExposureGoal) -> ExposedZones {
        switch goal {
        case .vitaminD:
            return [.face, .arms, .legs]
        case .gradualTan:
            return [.torso, .back, .arms, .legs]
        case .lowRisk:
            return [.face, .arms]
        }
    }

    private static func targetDose(
        for goal: SunExposureGoal,
        phototype: Fitzpatrick,
        zones: ExposedZones
    ) -> Double {
        switch goal {
        case .vitaminD:
            let synthesis = VitaminD.synthesisEfficiency(for: phototype)
            let iuPerMEDForZones = VitaminD.iuPerFullBodyMED * zones.bodyFraction * synthesis
            let doseForTargetIU = targetVitaminDIU / iuPerMEDForZones * phototype.med
            return min(doseForTargetIU, phototype.med * vitaminDMaximumFractionOfMED)
        case .gradualTan:
            return phototype.med * gradualTanFractionOfMED
        case .lowRisk:
            return phototype.med * lowRiskFractionOfMED
        }
    }

    private static func maximumMinutes(for goal: SunExposureGoal) -> Double {
        switch goal {
        case .vitaminD: return 30
        case .gradualTan: return 75
        case .lowRisk: return 45
        }
    }

    private static func suggestedSPF(
        for goal: SunExposureGoal,
        phototype: Fitzpatrick,
        uvIndex: Double
    ) -> Int {
        if uvIndex >= 8 {
            return phototype.rawValue <= Fitzpatrick.typeIII.rawValue ? 50 : 30
        }

        switch goal {
        case .vitaminD:
            return uvIndex >= 3 ? 30 : 15
        case .gradualTan:
            switch phototype {
            case .typeI, .typeII: return 50
            case .typeIII, .typeIV: return 30
            case .typeV, .typeVI: return 20
            }
        case .lowRisk:
            return uvIndex >= 6 || phototype.rawValue <= Fitzpatrick.typeIV.rawValue ? 50 : 30
        }
    }
}
