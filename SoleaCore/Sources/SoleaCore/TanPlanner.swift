import Foundation

public struct TanPlanDay: Identifiable, Hashable, Sendable {
    /// Indice del giorno nel piano (0 = primo giorno di preparazione).
    public let id: Int
    public let date: Date
    /// Minuti di esposizione consigliati per il giorno.
    public let minutes: Int
    /// SPF consigliato per il giorno.
    public let spf: Int
}

public enum TanPlannerError: Error, Equatable {
    case invalidPreparationDays(Int)
    case invalidUVIndex(Double)
}

/// Piano di esposizione graduale per arrivare preparati a una vacanza.
///
/// Euristica: si parte dal limite prudente a pelle nuda all'UV atteso e si cresce
/// linearmente fino al doppio (la tolleranza aumenta con la melanina prodotta),
/// con un tetto di 120 minuti/giorno. L'SPF consigliato parte alto e scende
/// gradualmente, senza mai andare sotto il minimo del fototipo.
public enum TanPlanner {
    public static let maximumDailyMinutes = 120
    public static let preparationDaysRange = 1...60
    public static let uvIndexRange = 1.0...12.0

    public static func plan(
        phototype: Fitzpatrick,
        preparationDays: Int,
        expectedUVIndex: Double,
        startingFrom startDate: Date,
        calendar: Calendar = .current
    ) throws -> [TanPlanDay] {
        guard preparationDaysRange.contains(preparationDays) else {
            throw TanPlannerError.invalidPreparationDays(preparationDays)
        }
        guard expectedUVIndex.isFinite, uvIndexRange.contains(expectedUVIndex) else {
            throw TanPlannerError.invalidUVIndex(expectedUVIndex)
        }

        let bareSafeMinutes = try SafeExposure.minutes(
            phototype: phototype,
            uvIndex: expectedUVIndex
        )
        let startDay = calendar.startOfDay(for: startDate)

        return (0..<preparationDays).map { index in
            let progress = preparationDays == 1
                ? 1.0
                : Double(index) / Double(preparationDays - 1)
            let minutes = min(
                Double(maximumDailyMinutes),
                bareSafeMinutes * (1.0 + progress)
            )
            guard let date = calendar.date(byAdding: .day, value: index, to: startDay) else {
                // Il calendario gregoriano produce sempre questa data; se un
                // calendario custom non ci riesce, meglio fermarsi che inventare.
                preconditionFailure("Impossibile calcolare la data del giorno \(index)")
            }
            return TanPlanDay(
                id: index,
                date: date,
                minutes: roundedToFive(minutes),
                spf: spfForDay(progress: progress, phototype: phototype)
            )
        }
    }

    /// SPF iniziale e finale del piano per fototipo.
    static func spfRange(for phototype: Fitzpatrick) -> (start: Int, end: Int) {
        switch phototype {
        case .typeI, .typeII: return (50, 30)
        case .typeIII: return (30, 20)
        case .typeIV: return (30, 15)
        case .typeV, .typeVI: return (20, 10)
        }
    }

    private static func spfForDay(progress: Double, phototype: Fitzpatrick) -> Int {
        let range = spfRange(for: phototype)
        let value = Double(range.start) + (Double(range.end) - Double(range.start)) * progress
        return Int(value.rounded())
    }

    private static func roundedToFive(_ value: Double) -> Int {
        max(5, Int((value / 5).rounded()) * 5)
    }
}
