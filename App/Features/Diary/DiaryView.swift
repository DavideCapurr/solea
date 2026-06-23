import SwiftUI
import SwiftData
import SoleaCore

struct DiaryView: View {
    let hasSoleaPlus: Bool

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TanSession.startedAt, order: .reverse) private var sessions: [TanSession]
    @State private var deleteErrorMessage: String?
    @State private var showPlusPaywall = false

    private var statColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Diario")
                .sheet(isPresented: $showPlusPaywall) {
                    SoleaPlusPaywallView(source: "diary")
                }
                .alert(
                    "Eliminazione non riuscita",
                    isPresented: Binding(
                        get: { deleteErrorMessage != nil },
                        set: { if !$0 { deleteErrorMessage = nil } }
                    )
                ) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(deleteErrorMessage ?? "")
                }
        }
        .tint(SoleaTheme.sunset)
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                diaryHero
                weeklyStatsGrid
                quickFeatureCards
                sessionsSection
            }
            .padding()
        }
        .background(SoleaTheme.screenGradient.ignoresSafeArea())
    }

    private var diaryHero: some View {
        let summary = lifetimeSummary

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("DIARIO SOLEA", systemImage: "book.closed.fill")
                    .font(.caption.bold())
                    .tracking(1.1)
                Spacer()
                Text(Date.now, format: .dateTime.day().month(.abbreviated))
                    .font(.caption.bold())
                    .foregroundStyle(.black.opacity(0.58))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(heroTitle)
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .foregroundStyle(.black.opacity(0.86))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                Text(heroSubtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.black.opacity(0.68))
            }

            HStack(spacing: 8) {
                heroMetric(
                    value: "\(summary.count)",
                    label: "sessioni",
                    icon: "checkmark.seal.fill"
                )
                heroMetric(
                    value: durationText(seconds: summary.minutes * 60),
                    label: "al sole",
                    icon: "timer"
                )
                heroMetric(
                    value: "≈ \(summary.vitaminD)",
                    label: "IU",
                    icon: "pills.fill"
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SoleaTheme.sunriseGradient, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.orange.opacity(0.20), lineWidth: 1)
        }
    }

    private var heroTitle: String {
        if sessions.isEmpty {
            return String(localized: "Il tuo primo sole smart")
        }
        return String(localized: "\(sessions.count) sessioni salvate")
    }

    private var heroSubtitle: String {
        guard let lastSession = sessions.first else {
            return String(localized: "Avvia una sessione dalla tab Oggi: durata, UV e note appariranno qui.")
        }
        let date = lastSession.startedAt.formatted(date: .abbreviated, time: .shortened)
        return String(localized: "Ultima sessione: \(date), \(durationText(lastSession.duration)).")
    }

    private func heroMetric(value: String, label: LocalizedStringKey, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.caption.bold())
            Text(value)
                .font(.headline.bold())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(.black.opacity(0.54))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 14))
    }

    private var weeklyStatsGrid: some View {
        let summary = weeklySummary

        return LazyVGrid(columns: statColumns, spacing: 12) {
            statTile(
                title: "Questa settimana",
                value: "\(summary.count)",
                detail: "sessioni",
                icon: "calendar",
                tint: SoleaTheme.sunset
            )
            statTile(
                title: "Tempo smart",
                value: durationText(seconds: summary.minutes * 60),
                detail: "negli ultimi giorni",
                icon: "sun.max.fill",
                tint: SoleaTheme.sunshine
            )
            statTile(
                title: "Vitamina D",
                value: "≈ \(summary.vitaminD)",
                detail: "IU stimate",
                icon: "pills.fill",
                tint: SoleaTheme.mint
            )
            statTile(
                title: "Soglia prudente",
                value: safetySummary,
                detail: "sessioni sotto limite",
                icon: "shield.lefthalf.filled",
                tint: SoleaTheme.aqua
            )
        }
    }

    private func statTile(
        title: LocalizedStringKey,
        value: String,
        detail: LocalizedStringKey,
        icon: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.16), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.bold())
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 136, alignment: .topLeading)
        .background(SoleaTheme.softGradient(from: tint), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var quickFeatureCards: some View {
        VStack(spacing: 12) {
            if hasSoleaPlus {
                NavigationLink {
                    PhotoDiaryView(hasSoleaPlus: hasSoleaPlus)
                } label: {
                    featureCard(
                        title: "Diario fotografico",
                        subtitle: "Confronta prima e dopo, tono e progressi visivi.",
                        icon: "camera.fill",
                        tint: SoleaTheme.coral
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    showPlusPaywall = true
                } label: {
                    featureCard(
                        title: "Foto-diario prima/dopo",
                        subtitle: "Plus aggiunge foto, confronto e analisi tono locale.",
                        icon: "camera.filters",
                        tint: SoleaTheme.coral,
                        badge: "Plus"
                    )
                }
                .buttonStyle(.plain)
            }

            if hasSoleaPlus {
                historicalTrendCard
            } else {
                Button {
                    showPlusPaywall = true
                } label: {
                    featureCard(
                        title: "Trend storici",
                        subtitle: "Sblocca andamento mensile, dose media e progressi nel tempo.",
                        icon: "chart.xyaxis.line",
                        tint: SoleaTheme.violet,
                        badge: "Plus"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func featureCard(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        icon: String,
        tint: Color,
        badge: LocalizedStringKey? = nil
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                    if let badge {
                        Text(badge)
                            .font(.caption2.bold())
                            .foregroundStyle(.black.opacity(0.76))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(SoleaTheme.sunshine.opacity(0.62), in: Capsule())
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        }
    }

    private var historicalTrendCard: some View {
        let summary = historicalSummary

        return coloredCard(tint: SoleaTheme.violet) {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Trend storici", icon: "chart.xyaxis.line", tint: SoleaTheme.violet)

                HStack(spacing: 12) {
                    trendMetric("30 giorni", value: "\(summary.last30)", detail: "sessioni")
                    Divider()
                    trendMetric("Minuti smart", value: "\(summary.smartMinutes)", detail: trendText(
                        current: summary.smartMinutes,
                        previous: summary.previousSmartMinutes
                    ))
                    Divider()
                    trendMetric(
                        "Dose media",
                        value: "\(Int(summary.doseAverage.rounded()))%",
                        detail: "MED"
                    )
                }
            }
        }
    }

    private func trendMetric(
        _ title: LocalizedStringKey,
        value: String,
        detail: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.bold())
                .monospacedDigit()
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Sessioni", icon: "clock.arrow.circlepath", tint: SoleaTheme.sunset)

            if sessions.isEmpty {
                emptySessionsCard
            } else {
                VStack(spacing: 10) {
                    ForEach(sessions) { session in
                        sessionRow(session)
                    }
                }
            }
        }
    }

    private var emptySessionsCard: some View {
        coloredCard(tint: SoleaTheme.sunset) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "sun.max.trianglebadge.exclamationmark")
                    .font(.title2)
                    .foregroundStyle(SoleaTheme.sunset)
                Text("Nessuna sessione ancora")
                    .font(.headline)
                Text("Avvia la tua prima sessione dalla tab Oggi: la troverai qui con durata, UV, vitamina D stimata e note.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func sessionRow(_ session: TanSession) -> some View {
        HStack(alignment: .center, spacing: 10) {
            NavigationLink {
                sessionDetail(session)
            } label: {
                sessionCard(session)
            }
            .buttonStyle(.plain)

            Menu {
                Button(role: .destructive) {
                    delete(session)
                } label: {
                    Label("Elimina", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title3)
                    .foregroundStyle(SoleaTheme.sunset)
                    .frame(width: 38, height: 38)
                    .background(.regularMaterial, in: Circle())
            }
            .accessibilityLabel("Azioni sessione")
        }
    }

    private func sessionCard(_ session: TanSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                    Label {
                        Text(goalTitle(session.goal))
                    } icon: {
                        Image(systemName: "target")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(durationText(session.duration))
                        .font(.title3.bold())
                        .monospacedDigit()
                    Text("UV \(session.averageUVIndex.formatted(.number.precision(.fractionLength(1))))")
                        .font(.caption.bold())
                        .foregroundStyle(SoleaTheme.sunset)
                }
            }

            HStack(spacing: 8) {
                miniPill("SPF \(Int(session.spf))", icon: "shield.lefthalf.filled", tint: SoleaTheme.aqua)
                miniPill("≈ \(Int(session.vitaminDIU)) IU", icon: "pills.fill", tint: SoleaTheme.mint)
                if let fraction = session.fractionOfMED {
                    miniPill(
                        fraction.formatted(.percent.precision(.fractionLength(0))),
                        icon: "gauge.with.needle",
                        tint: fraction < SafeExposure.recommendedLimitFractionOfMED ? SoleaTheme.mint : .red
                    )
                }
            }

            HStack(spacing: 10) {
                Label(sideSplitText(session), systemImage: "arrow.left.and.right")
                if session.skinResponse != .notLogged {
                    Label(skinResponseTitle(session.skinResponse), systemImage: "hand.raised.fill")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(SoleaTheme.sunset.opacity(0.14), lineWidth: 1)
        }
    }

    private func miniPill(_ title: String, icon: String, tint: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.caption2.bold())
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
    }

    private func sectionHeader(_ title: LocalizedStringKey, icon: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }

    private func coloredCard<Content: View>(
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SoleaTheme.softGradient(from: tint), in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(tint.opacity(0.16), lineWidth: 1)
            }
    }

    private var lifetimeSummary: (count: Int, minutes: Int, vitaminD: Int) {
        let minutes = Int(sessions.reduce(0) { $0 + $1.duration } / 60)
        let vitaminD = Int(sessions.reduce(0) { $0 + $1.vitaminDIU })
        return (sessions.count, minutes, vitaminD)
    }

    private var weeklySummary: (count: Int, minutes: Int, vitaminD: Int) {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        let weekSessions = sessions.filter { $0.startedAt >= weekStart }
        let minutes = Int(weekSessions.reduce(0) { $0 + $1.duration } / 60)
        let vitaminD = Int(weekSessions.reduce(0) { $0 + $1.vitaminDIU })
        return (weekSessions.count, minutes, vitaminD)
    }

    private var historicalSummary: (
        last30: Int,
        smartMinutes: Int,
        previousSmartMinutes: Int,
        doseAverage: Double
    ) {
        let calendar = Calendar.current
        let last30Start = calendar.date(byAdding: .day, value: -30, to: .now) ?? .now
        let previous30Start = calendar.date(byAdding: .day, value: -60, to: .now) ?? .now
        let last30 = sessions.filter { $0.startedAt >= last30Start }
        let previous30 = sessions.filter { $0.startedAt >= previous30Start && $0.startedAt < last30Start }
        let smartMinutes = Int(last30
            .filter { ($0.fractionOfMED ?? 0) <= Streaks.smartThreshold }
            .reduce(0) { $0 + $1.duration } / 60)
        let previousSmartMinutes = Int(previous30
            .filter { ($0.fractionOfMED ?? 0) <= Streaks.smartThreshold }
            .reduce(0) { $0 + $1.duration } / 60)
        let doseAverage = last30.isEmpty
            ? 0
            : last30.reduce(0) { $0 + (($1.fractionOfMED ?? 0) * 100) } / Double(last30.count)
        return (last30.count, smartMinutes, previousSmartMinutes, doseAverage)
    }

    private var safetySummary: String {
        guard !sessions.isEmpty else { return "0/0" }
        let safeSessions = sessions.filter {
            ($0.fractionOfMED ?? 0) <= SafeExposure.recommendedLimitFractionOfMED
        }
        return "\(safeSessions.count)/\(sessions.count)"
    }

    private func trendText(current: Int, previous: Int) -> String {
        let delta = current - previous
        if delta == 0 {
            return String(localized: "stabile")
        }
        let sign = delta > 0 ? "+" : ""
        return "\(sign)\(delta) min"
    }

    private func sessionDetail(_ session: TanSession) -> some View {
        List {
            Section("Riepilogo") {
                LabeledContent("Obiettivo") {
                    Text(goalTitle(session.goal))
                }
                LabeledContent("Durata") {
                    Text(durationText(session.duration))
                }
                if session.pauseSeconds > 0 {
                    LabeledContent("Pausa") {
                        Text(durationText(seconds: session.pauseSeconds))
                    }
                }
                if session.plannedMinutes > 0 {
                    LabeledContent("Durata obiettivo") {
                        Text("\(session.plannedMinutes) min")
                    }
                }
                LabeledContent("UV medio") {
                    Text(session.averageUVIndex, format: .number.precision(.fractionLength(1)))
                }
                LabeledContent("SPF") {
                    Text(session.spf == 1 ? String(localized: "Nessuna") : "SPF \(Int(session.spf))")
                }
                LabeledContent("Vitamina D stimata") {
                    Text("≈ \(Int(session.vitaminDIU.rounded())) IU")
                }
                if let fraction = session.fractionOfMED {
                    LabeledContent("Quota della MED") {
                        Text(fraction, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(fraction < SafeExposure.recommendedLimitFractionOfMED ? .primary : Color.red)
                    }
                }
            }

            Section("Uniformità") {
                LabeledContent("Fronte") {
                    Text(durationText(seconds: session.frontSeconds))
                }
                LabeledContent("Retro") {
                    Text(durationText(seconds: session.backSeconds))
                }
                Text(sideBalanceText(session))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Pelle e note") {
                LabeledContent("Sensazione") {
                    Text(skinResponseTitle(session.skinResponse))
                }
                if session.noteText.isEmpty {
                    Text("Nessuna nota salvata.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(session.noteText)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(SoleaTheme.screenGradient.ignoresSafeArea())
        .navigationTitle(session.startedAt.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let seconds = Int(duration.rounded())
        if seconds < 60 {
            return String(localized: "\(seconds) s")
        }
        let minutes = Int((Double(seconds) / 60).rounded())
        if minutes >= 60 {
            return String(localized: "\(minutes / 60) h \(minutes % 60) min")
        }
        return String(localized: "\(minutes) min")
    }

    private func durationText(seconds: Int) -> String {
        if seconds < 60 {
            return String(localized: "\(seconds) s")
        }
        let minutes = seconds / 60
        if minutes >= 60 {
            return String(localized: "\(minutes / 60) h \(minutes % 60) min")
        }
        return String(localized: "\(minutes) min")
    }

    private func sideSplitText(_ session: TanSession) -> String {
        let front = session.frontSeconds / 60
        let back = session.backSeconds / 60
        return String(localized: "F \(front) / R \(back) min")
    }

    private func sideBalanceText(_ session: TanSession) -> String {
        let total = session.frontSeconds + session.backSeconds
        let difference = abs(session.frontSeconds - session.backSeconds)
        if total == 0 {
            return String(localized: "Questa sessione non ha tracciamento fronte/retro.")
        }
        if difference >= 10 * 60 {
            return String(localized: "Sbilanciata: parti dal lato meno esposto nella prossima sessione.")
        }
        if difference >= 5 * 60 {
            return String(localized: "Quasi uniforme: manca poco per pareggiare i lati.")
        }
        return String(localized: "Uniforme: fronte e retro sono ben bilanciati.")
    }

    private func goalTitle(_ goal: SunExposureGoal) -> LocalizedStringKey {
        switch goal {
        case .vitaminD: return "Vitamina D"
        case .gradualTan: return "Abbronzatura graduale"
        case .lowRisk: return "Prudenza"
        }
    }

    private func skinResponseTitle(_ response: SkinResponse) -> LocalizedStringKey {
        switch response {
        case .notLogged: return "Non registrata"
        case .comfortable: return "Bene"
        case .warm: return "Calda"
        case .tight: return "Tira"
        case .red: return "Arrossata"
        }
    }

    private func delete(_ session: TanSession) {
        modelContext.delete(session)
        do {
            try modelContext.save()
        } catch {
            deleteErrorMessage = error.localizedDescription
        }
    }
}
