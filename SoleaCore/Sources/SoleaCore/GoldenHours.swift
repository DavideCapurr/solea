import Foundation

/// Le "golden hours": finestre orarie in cui il rapporto abbronzatura/rischio è
/// ottimale per il fototipo — UV abbastanza alto da abbronzare, ma non oltre la
/// soglia in cui il rischio cresce troppo in fretta per quella pelle.
public enum GoldenHours {
    /// UV minimo perché l'esposizione abbia un effetto abbronzante apprezzabile.
    public static let minimumTanningUVIndex = 2.5

    /// UV massimo consigliato per abbronzarsi in base al fototipo.
    public static func maximumUVIndex(for phototype: Fitzpatrick) -> Double {
        switch phototype {
        case .typeI: return 5
        case .typeII: return 6
        case .typeIII: return 7
        case .typeIV: return 8
        case .typeV: return 9
        case .typeVI: return 10
        }
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
