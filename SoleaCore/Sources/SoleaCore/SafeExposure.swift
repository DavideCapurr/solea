import Foundation

public enum SafeExposureError: Error, Equatable {
    case invalidUVIndex(Double)
    case invalidSPF(Double)
    case invalidDuration(Double)
    case invalidTargetDoseFraction(Double)
}

/// Calcolo del limite prudente di esposizione e della dose UV ricevuta.
///
/// Convenzione standard: 1 punto di indice UV ≈ 0.025 W/m² di irradianza
/// eritemale (pesatura CIE). La MED è una soglia di eritema osservabile, non
/// un obiettivo da raggiungere: il limite raccomandato resta sotto la MED.
public enum SafeExposure {
    /// Irradianza eritemale (W/m²) per unità di indice UV.
    public static let wattsPerUVIndexUnit = 0.025

    /// Sotto questa soglia l'UV è considerato trascurabile: nessun limite di tempo.
    public static let negligibleUVIndex = 0.5

    /// Frazione prudente della MED oltre la quale l'app considera alto il rischio.
    public static let recommendedLimitFractionOfMED = 0.8

    /// Durata massima considerata coperta da una singola applicazione di SPF.
    /// Le linee guida FDA richiedono riapplicazione almeno ogni 2 ore.
    public static let maximumMinutesPerSunscreenApplication = 120.0

    /// Fattore SPF massimo usato dal modello: SPF oltre 50 non viene amplificato.
    public static let maximumModeledSPF = 50.0

    /// Dose prudente raccomandata per il fototipo.
    public static func recommendedDoseLimit(phototype: Fitzpatrick) -> Double {
        phototype.med * recommendedLimitFractionOfMED
    }

    /// Minuti di esposizione prima di raggiungere la frazione target della MED.
    /// Ritorna `.infinity` quando l'UV è trascurabile.
    public static func minutes(
        phototype: Fitzpatrick,
        uvIndex: Double,
        spf: Double = 1,
        targetDoseFraction: Double = recommendedLimitFractionOfMED
    ) throws -> Double {
        guard uvIndex >= 0, uvIndex.isFinite else { throw SafeExposureError.invalidUVIndex(uvIndex) }
        guard spf >= 1, spf.isFinite else { throw SafeExposureError.invalidSPF(spf) }
        guard targetDoseFraction > 0, targetDoseFraction <= 1, targetDoseFraction.isFinite else {
            throw SafeExposureError.invalidTargetDoseFraction(targetDoseFraction)
        }
        guard uvIndex > negligibleUVIndex else { return .infinity }
        let dosePerMinute = uvIndex * wattsPerUVIndexUnit * 60 // J/m² al minuto
        let modeledSPF = min(spf, maximumModeledSPF)
        let doseLimitedMinutes = phototype.med * targetDoseFraction * modeledSPF / dosePerMinute
        guard spf > 1 else { return doseLimitedMinutes }
        return min(doseLimitedMinutes, maximumMinutesPerSunscreenApplication)
    }

    /// Dose eritemale effettivamente assorbita (J/m²) in `minutes` minuti a `uvIndex`,
    /// attenuata dall'SPF applicato.
    public static func dose(
        uvIndex: Double,
        minutes: Double,
        spf: Double = 1
    ) throws -> Double {
        guard uvIndex >= 0, uvIndex.isFinite else { throw SafeExposureError.invalidUVIndex(uvIndex) }
        guard spf >= 1, spf.isFinite else { throw SafeExposureError.invalidSPF(spf) }
        guard minutes >= 0, minutes.isFinite else { throw SafeExposureError.invalidDuration(minutes) }
        return uvIndex * wattsPerUVIndexUnit * 60 * minutes / min(spf, maximumModeledSPF)
    }
}
