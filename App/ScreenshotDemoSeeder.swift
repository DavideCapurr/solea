import Foundation
import SwiftData
import SoleaCore

#if DEBUG
enum ScreenshotDemoSeeder {
    static let launchArgument = "-soleaScreenshotDemo"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        guard isEnabled else { return }
        do {
            if try context.fetch(FetchDescriptor<UserProfile>()).isEmpty {
                try seed(in: context)
            }
        } catch {
            assertionFailure("Screenshot demo seed failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    private static func seed(in context: ModelContext) throws {
        let now = Calendar.current.date(from: DateComponents(
            year: 2026,
            month: 6,
            day: 16,
            hour: 10,
            minute: 30
        )) ?? .now

        let phototype = Fitzpatrick.typeIII
        context.insert(UserProfile(phototype: phototype, quizScore: 18, createdAt: now.addingTimeInterval(-14 * 86_400)))

        let sessions: [TanSession] = [
            TanSession(
                startedAt: now.addingTimeInterval(-2 * 86_400),
                endedAt: now.addingTimeInterval(-2 * 86_400 + 28 * 60),
                spf: 30,
                exposedZones: [.face, .arms, .legs],
                averageUVIndex: 5.8,
                uvDose: 86,
                vitaminDIU: 620,
                phototype: phototype,
                goal: .gradualTan,
                frontExposureSeconds: 14 * 60,
                backExposureSeconds: 14 * 60,
                plannedDurationMinutes: 30,
                exposureSeconds: 28 * 60,
                pausedSeconds: 4 * 60,
                skinResponse: .comfortable,
                note: "Sessione equilibrata: nessun rossore, SPF riapplicato."
            ),
            TanSession(
                startedAt: now.addingTimeInterval(-1 * 86_400),
                endedAt: now.addingTimeInterval(-1 * 86_400 + 22 * 60),
                spf: 50,
                exposedZones: [.face, .arms],
                averageUVIndex: 7.2,
                uvDose: 58,
                vitaminDIU: 410,
                phototype: phototype,
                goal: .lowRisk,
                frontExposureSeconds: 12 * 60,
                backExposureSeconds: 10 * 60,
                plannedDurationMinutes: 25,
                exposureSeconds: 22 * 60,
                pausedSeconds: 6 * 60,
                skinResponse: .warm,
                note: "UV alto: pausa all'ombra dopo lo stop prudente."
            ),
            TanSession(
                startedAt: now,
                endedAt: now.addingTimeInterval(18 * 60),
                spf: 30,
                exposedZones: [.face, .arms, .legs],
                averageUVIndex: 4.6,
                uvDose: 62,
                vitaminDIU: 510,
                phototype: phototype,
                goal: .vitaminD,
                frontExposureSeconds: 9 * 60,
                backExposureSeconds: 9 * 60,
                plannedDurationMinutes: 20,
                exposureSeconds: 18 * 60,
                pausedSeconds: 3 * 60,
                skinResponse: .comfortable,
                note: "Dose breve per vitamina D, pelle confortevole."
            )
        ]
        sessions.forEach(context.insert)

        let planDays = (0..<7).map { offset in
            StoredPlanDay(
                id: offset + 1,
                date: now.addingTimeInterval(TimeInterval((offset + 1) * 86_400)),
                minutes: min(18 + offset * 3, 35),
                spf: offset < 4 ? 50 : 30
            )
        }
        context.insert(try VacationPlan(
            destinationName: "Naxos",
            departureDate: now.addingTimeInterval(7 * 86_400),
            expectedUVIndex: 7.4,
            phototypeRawValue: phototype.rawValue,
            days: planDays,
            createdAt: now.addingTimeInterval(-3 * 86_400)
        ))

        try context.save()
    }
}
#endif
