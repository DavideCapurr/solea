import Foundation

public enum SafeExposureError: Error, Equatable {
    case invalidUVIndex(Double)
    case invalidSPF(Double)
    case invalidDuration(Double)
}

/// Calcolo del tempo di esposizione sicura e della dose UV ricevuta.
///
/// Convenzione standard: 1 punto di indice UV ≈ 0.025 W/m² di irradianza
/// eritemale (pesatura CIE). Il tempo sicuro è il tempo necessario a
/// raggiungere la MED del fototipo, moltiplicato per l'SPF applicato.
public enum SafeExposure {
    /// Irradianza eritemale (W/m²) per unità di indice UV.
    public static let wattsPerUVIndexUnit = 0.025

    /// Sotto questa soglia l'UV è considerato trascurabile: nessun limite di tempo.
    public static let negligibleUVIndex = 0.5

    /// Minuti di esposizione prima di raggiungere la MED.
    /// Ritorna `.infinity` quando l'UV è trascurabile.
    public static func minutes(
        phototype: Fitzpatrick,
        uvIndex: Double,
        spf: Double = 1
    ) throws -> Double {
        guard uvIndex >= 0, uvIndex.isFinite else { throw SafeExposureError.invalidUVIndex(uvIndex) }
        guard spf >= 1, spf.isFinite else { throw SafeExposureError.invalidSPF(spf) }
        guard uvIndex > negligibleUVIndex else { return .infinity }
        let dosePerMinute = uvIndex * wattsPerUVIndexUnit * 60 // J/m² al minuto
        return phototype.med * spf / dosePerMinute
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
        return uvIndex * wattsPerUVIndexUnit * 60 * minutes / spf
    }
}
