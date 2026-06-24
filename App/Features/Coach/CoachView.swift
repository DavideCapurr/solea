import SwiftUI
import SwiftData
import SoleaCore

struct CoachView: View {
    let phototype: Fitzpatrick
    /// UV attuale se già noto dalla schermata Oggi (può essere nil).
    let currentUVIndex: Double?
    let hasSoleaPlus: Bool

    @Query(sort: \TanSession.startedAt, order: .reverse) private var sessions: [TanSession]
    @Query(sort: \VacationPlan.departureDate, order: .forward) private var plans: [VacationPlan]
    @State private var viewModel = CoachViewModel()

    private var context: CoachContext {
        let now = Date.now
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? startOfDay
        let completedSessions = sessions.filter { $0.startedAt <= now }
        let records = completedSessions.map {
            SessionRecord(day: $0.startedAt, fractionOfMED: $0.fractionOfMED ?? 0, vitaminDIU: $0.vitaminDIU)
        }
        let todaySessions = completedSessions.filter { $0.startedAt >= startOfDay }
        let recentSessions = completedSessions.prefix(3).map {
            CoachSessionSnapshot(
                date: $0.startedAt,
                exposureMinutes: Int(($0.duration / 60).rounded()),
                averageUVIndex: $0.averageUVIndex,
                spf: $0.spf,
                fractionOfMED: $0.fractionOfMED,
                skinResponse: $0.skinResponse
            )
        }
        return CoachContext(
            phototype: phototype,
            currentUVIndex: currentUVIndex,
            todaySessionCount: todaySessions.count,
            todayMEDFraction: todaySessions.compactMap(\.fractionOfMED).reduce(0, +),
            weekSessionCount: completedSessions.filter { $0.startedAt >= sevenDaysAgo }.count,
            currentStreak: Streaks.currentStreak(records: records, today: now),
            recentSessions: Array(recentSessions),
            nextVacationPlan: nextVacationPlanSnapshot(startOfDay: startOfDay)
        )
    }

    private func nextVacationPlanSnapshot(startOfDay: Date) -> CoachVacationPlanSnapshot? {
        guard let plan = plans.first(where: { $0.departureDate >= startOfDay }) else {
            return nil
        }
        let days = (try? plan.days()) ?? []
        let nextDay = days.first { $0.date >= startOfDay } ?? days.first
        return CoachVacationPlanSnapshot(
            destinationName: plan.destinationName,
            departureDate: plan.departureDate,
            expectedUVIndex: plan.expectedUVIndex,
            dayCount: days.count,
            nextDayMinutes: nextDay?.minutes,
            nextDaySPF: nextDay?.spf
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if !hasSoleaPlus {
                    SoleaPlusLockedView(
                        title: "Coach AI Plus",
                        message: "Sblocca il coach cloud per domande su SPF, progressione e preparazione alle vacanze.",
                        systemImage: "bubble.left.and.bubble.right.fill",
                        source: "coach"
                    )
                } else if viewModel.isAvailable {
                    chat
                } else {
                    ContentUnavailableView {
                        Label("Coach non disponibile", systemImage: "bubble.left.and.exclamationmark.bubble.right")
                    } description: {
                        Text("Il Coach richiede il modello on-device (iOS 26+) oppure la configurazione del proxy cloud.")
                    }
                }
            }
            .navigationTitle("Coach")
        }
    }

    private var chat: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if viewModel.messages.isEmpty {
                            intro
                        }
                        ForEach(viewModel.messages) { message in
                            bubble(message)
                                .id(message.id)
                        }
                        if let error = viewModel.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.last?.text) { _, _ in
                    if let last = viewModel.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            inputBar
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ciao! Sono il tuo Coach Solare ☀️")
                .font(.headline)
            Text("Chiedimi quanto puoi startene al sole oggi, che SPF usare, o come prepararti per le vacanze.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            availabilityBadge(viewModel.availability)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }

    private func availabilityBadge(_ availability: CoachAvailability) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(availability.title, systemImage: availability.systemImage)
                .font(.caption.bold())
                .foregroundStyle(.primary)
            Text(availability.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func bubble(_ message: CoachMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text.isEmpty ? "…" : message.text)
                .padding(10)
                .background(
                    message.role == .user ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Scrivi al coach…", text: $viewModel.draft, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
            if viewModel.isResponding {
                Button {
                    viewModel.cancel()
                } label: {
                    Image(systemName: "stop.circle.fill").font(.title2)
                }
            } else {
                Button {
                    viewModel.send(context: context)
                } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.title2)
                }
                .disabled(!viewModel.canSend)
            }
        }
        .padding()
        .background(.bar)
    }
}
