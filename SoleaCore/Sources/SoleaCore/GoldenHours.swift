import Foundation

/// Le "golden hours": finestre orarie in cui il rapporto abbronzatura/rischio è
/// ottimale per il fototipo — UV abbastanza alto da abbronzare, ma non oltre la
/// soglia in cui il rischio cresce troppo in fretta per quella pelle.
public enum GoldenHours {
    /// UV minimo perché l'esposizione abbia un effetto abbronzante apprezzabile.
    public static let minimumTanningUVIndex = 2.5

    /// Una finestra "golden" non dovrebbe richiedere stop quasi immediato.
    public static let minimumRecommendedBareMinutes = 25.0

    /// Sopra UV 7 si entra in fasce alte/molto alte: non vengono marcate come ideali.
    public static let absoluteMaximumGoldenUVIndex = 7.0

    /// UV massimo consigliato per abbronzarsi in base al fototipo e alla soglia prudente.
    public static func maximumUVIndex(for phototype: Fitzpatrick) -> Double {
        let dosePerMinuteAtUVI1 = SafeExposure.wattsPerUVIndexUnit * 60
        let exposureBasedCap = SafeExposure.recommendedDoseLimit(phototype: phototype)
            / (minimumRecommendedBareMinutes * dosePerMinuteAtUVI1)
        return min(absoluteMaximumGoldenUVIndex, exposureBasedCap)
    }

    /// Estrae dalle previsioni orarie le finestre contigue ideali per il fototipo.
    /// Ogni campione copre un'ora; le ore consecutive vengono fuse in un unico intervallo.
    public static func windows(in forecast: [UVHour], phototype: Fitzpatrick) -> [DateInterval] {
        let cap = maximumUVIndex(for: phototype)
        let goodHours = forecast
            .sorted { $0.date < $1.date }
            .filter { $0.uvIndex >= minimumTanningUVIndex && $0.uvIndex <= cap }

        var windows: [DateInterval] = []
        for hour in goodHours {
            if let last = windows.last, abs(hour.date.timeIntervalSince(last.end)) < 1 {
                windows[windows.count - 1] = DateInterval(
                    start: last.start,
                    duration: last.duration + 3600
                )
            } else {
                windows.append(DateInterval(start: hour.date, duration: 3600))
            }
        }
        return windows
    }
}
