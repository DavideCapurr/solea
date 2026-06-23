import SwiftUI
import SwiftData
import SoleaCore

struct ProfileView: View {
    let phototype: Fitzpatrick
    var connectivity: PhoneConnectivityService

    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [TanSession]
    @Query private var plans: [VacationPlan]

    @Environment(SoleaPlusStore.self) private var plusStore
    @State private var gameCenter = GameCenterService()
    @State private var showResetConfirmation = false
    @State private var resetErrorMessage: String?
    @State private var sharePayload: SharePayload?
    @State private var showPlusPaywall = false
    @State private var gameCenterWarning: String?
    @Environment(\.openURL) private var openURL

    // MARK: - Progressi derivati (logica in SoleaCore)

    private var records: [SessionRecord] {
        sessions.map {
            SessionRecord(
                day: $0.startedAt,
                fractionOfMED: $0.fractionOfMED ?? 0,
                vitaminDIU: $0.vitaminDIU
            )
        }
    }

    private var currentStreak: Int {
        Streaks.currentStreak(records: records, today: .now)
    }

    private var totalVitaminD: Double {
        sessions.reduce(0) { $0 + $1.vitaminDIU }
    }

    private var progress: BadgeProgress {
        BadgeProgress(
            sessionCount: sessions.count,
            currentStreak: currentStreak,
            completedPlans: plans.count,
            totalVitaminDIU: totalVitaminD
        )
    }

    private var unlockedBadges: Set<Badge> {
        Badge.unlocked(for: progress)
    }

    var body: some View {
        NavigationStack {
            List {
                skinSection
                plusSection
                streakSection
                badgesSection
                shareSection
                informationSection
                resetSection
            }
            .navigationTitle("Profilo")
            .task { await authenticateAndSync() }
            .confirmationDialog(
                "Vuoi rifare il quiz del fototipo?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Rifai il quiz", role: .destructive) { resetProfile() }
                Button("Annulla", role: .cancel) {}
            }
            .alert(
                "Operazione non riuscita",
                isPresented: Binding(
                    get: { resetErrorMessage != nil },
                    set: { if !$0 { resetErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resetErrorMessage ?? "")
            }
            .sheet(item: $sharePayload) { payload in
                ShareSheet(payload: payload)
            }
            .sheet(isPresented: $showPlusPaywall) {
                SoleaPlusPaywallView(source: "profile")
            }
        }
    }

    private var skinSection: some View {
        Section("La tua pelle") {
            HStack {
                Text("Fototipo")
                Spacer()
                Text(phototype.romanNumeral).bold().foregroundStyle(.orange)
            }
            Text(LocalizedStringKey(phototype.summaryKey))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Text("Dose massima (MED)")
                Spacer()
                Text("\(Int(phototype.med)) J/m²").foregroundStyle(.secondary)
            }
            if let warning = connectivity.lastError {
                Label(
                    "Sincronizzazione del fototipo con l'Apple Watch non riuscita: \(warning)",
                    systemImage: "applewatch.slash"
                )
                .font(.footnote)
                .foregroundStyle(.orange)
            }
        }
    }

    private var streakSection: some View {
        Section("Serie") {
            HStack {
                Label("Giorni di sole intelligente", systemImage: "flame.fill")
                    .foregroundStyle(.orange)
                Spacer()
                Text("\(currentStreak)").bold()
            }
        }
    }

    private var plusSection: some View {
        Section("Solea Plus") {
            HStack {
                Label(
                    plusStore.hasPlus ? "Plus attivo" : "Piano gratuito",
                    systemImage: plusStore.hasPlus ? "sparkles" : "sun.max"
                )
                .foregroundStyle(plusStore.hasPlus ? .orange : .primary)
                Spacer()
                if let validUntil = plusStore.entitlement.validUntil, plusStore.hasPlus {
                    Text(validUntil, format: .dateTime.day().month().year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                showPlusPaywall = true
            } label: {
                Label(
                    plusStore.hasPlus ? "Vedi opzioni App Store" : "Passa a Solea Plus",
                    systemImage: plusStore.hasPlus ? "checkmark.seal" : "sparkles"
                )
            }

            Text("Gratis: UV live, rischio scottatura, limite prudente, quiz, timer base, diario base e alert sicurezza. Plus: planner, coach cloud, foto-diario, trend, reminder, Watch/Live Activity e share card premium.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var badgesSection: some View {
        Section("Traguardi") {
            ForEach(Badge.allCases) { badge in
                let unlocked = unlockedBadges.contains(badge)
                HStack {
                    Image(systemName: badge.systemImage)
                        .foregroundStyle(unlocked ? .orange : .secondary)
                        .frame(width: 28)
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey(badge.titleKey))
                        Text(LocalizedStringKey(badge.detailKey))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if unlocked {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                    }
                }
                .opacity(unlocked ? 1 : 0.5)
            }
        }
    }

    private var shareSection: some View {
        Section {
            Button {
                if plusStore.hasPlus {
                    makeShareCard()
                } else {
                    showPlusPaywall = true
                }
            } label: {
                HStack {
                    Label("Crea la tua Solea Story", systemImage: "sparkles")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                }
            }
            if let warning = gameCenterWarning {
                Text(warning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var informationSection: some View {
        Section("Informazioni") {
            if let privacyPolicyURL = AppStoreLinks.privacyPolicyURL {
                Button {
                    openURL(privacyPolicyURL)
                } label: {
                    Label("Informativa privacy", systemImage: "hand.raised")
                }
            }

            if let supportURL = AppStoreLinks.supportURL {
                Button {
                    openURL(supportURL)
                } label: {
                    Label("Supporto", systemImage: "questionmark.circle")
                }
            }

            Text("Solea fornisce stime informative, non consigli medici.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var resetSection: some View {
        Section {
            Button("Rifai il quiz", role: .destructive) {
                showResetConfirmation = true
            }
        } footer: {
            Text("Il fototipo determina i limiti prudenti di esposizione: rifai il quiz se pensi che non ti rappresenti.")
        }
    }

    // MARK: - Azioni

    private func authenticateAndSync() async {
        await gameCenter.authenticate()
        guard gameCenter.isAuthenticated else {
            gameCenterWarning = GameCenterError.notAuthenticated.localizedDescription
            return
        }
        do {
            try await gameCenter.report(unlocked: unlockedBadges)
            try await gameCenter.submitLongestStreak(currentStreak)
            try await gameCenter.submitWeeklySmartMinutes(weeklySmartMinutes())
            gameCenterWarning = nil
        } catch {
            // Il fallimento di sync non blocca nulla in app: lo mostriamo soltanto.
            gameCenterWarning = error.localizedDescription
        }
    }

    private func weeklySmartMinutes() -> Int {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        return Int(sessions
            .filter { $0.startedAt >= weekStart && ($0.fractionOfMED ?? 0) <= Streaks.smartThreshold }
            .reduce(0) { $0 + $1.duration } / 60)
    }

    private func makeShareCard() {
        let message = currentStreak > 0
            ? String(localized: "Una serie costruita restando sotto la soglia prudente.")
            : String(localized: "Ogni giornata smart inizia da un check consapevole.")
        let card = ShareCardView(content: ShareCardContent(
            eyebrow: String(localized: "La mia serie Solea"),
            headline: "\(currentStreak)",
            unit: String(localized: "giorni di sole intelligente"),
            message: message,
            metrics: [
                ShareCardMetric(icon: "sun.max.fill", value: "\(sessions.count)", label: String(localized: "sessioni")),
                ShareCardMetric(icon: "medal.fill", value: "\(unlockedBadges.count)", label: String(localized: "traguardi")),
                ShareCardMetric(icon: "person.fill", value: phototype.romanNumeral, label: String(localized: "Fototipo"))
            ],
            symbol: "flame.fill"
        ))
        guard let payload = renderSharePayload(
            content: card,
            caption: String(localized: "La mia serie Solea è di \(currentStreak) giorni di sole intelligente. ☀️"),
            source: "profile_streak"
        ) else {
            gameCenterWarning = String(localized: "Impossibile generare l'immagine da condividere.")
            return
        }
        sharePayload = payload
    }

    private func resetProfile() {
        do {
            try modelContext.delete(model: UserProfile.self)
            try modelContext.save()
        } catch {
            resetErrorMessage = error.localizedDescription
        }
    }
}
