import Foundation

/// Riepilogo di una sessione necessario al calcolo di streak e badge,
/// indipendente dal layer di persistenza dell'app.
public struct SessionRecord: Hashable, Sendable {
    public let day: Date
    /// Frazione della MED raggiunta nella sessione (dose / MED del fototipo).
    public let fractionOfMED: Double
    public let vitaminDIU: Double

    public init(day: Date, fractionOfMED: Double, vitaminDIU: Double) {
        self.day = day
        self.fractionOfMED = fractionOfMED
        self.vitaminDIU = vitaminDIU
    }
}

/// Calcolo della "streak di esposizione intelligente": giorni consecutivi (fino
/// a oggi) con almeno una sessione e nessuna che abbia superato la soglia di rischio.
public enum Streaks {
    /// Una sessione conta come "smart" se resta sotto questa frazione di MED.
    public static let smartThreshold = 0.8

    public static func currentStreak(
        records: [SessionRecord],
        today: Date,
        calendar: Calendar = .current
    ) -> Int {
        // Raggruppa per giorno: un giorno è "smart" se ha sessioni e nessuna
        // supera la soglia.
        var smartDays: Set<Date> = []
        var unsafeDays: Set<Date> = []
        for record in records {
            let day = calendar.startOfDay(for: record.day)
            if record.fractionOfMED > smartThreshold {
                unsafeDays.insert(day)
            } else {
                smartDays.insert(day)
            }
        }

        var streak = 0
        var cursor = calendar.startOfDay(for: today)
        while smartDays.contains(cursor) && !unsafeDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
}
