import SwiftUI
import SwiftData
import SoleaCore

struct ProfileView: View {
    let phototype: Fitzpatrick

    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [TanSession]
    @Query private var plans: [VacationPlan]

    @State private var gameCenter = GameCenterService()
    @State private var showResetConfirmation = false
    @State private var resetErrorMessage: String?
    @State private var shareImage: ShareImage?
    @State private var gameCenterWarning: String?

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
                streakSection
                badgesSection
                shareSection
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
            .sheet(item: $shareImage) { item in
                ShareSheet(items: [item.image])
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
        }
    }

    private var streakSection: some View {
        Section("Streak") {
            HStack {
                Label("Giorni di sole intelligente", systemImage: "flame.fill")
                    .foregroundStyle(.orange)
                Spacer()
                Text("\(currentStreak)").bold()
            }
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
                makeShareCard()
            } label: {
                Label("Condividi i tuoi progressi", systemImage: "square.and.arrow.up")
            }
            if let warning = gameCenterWarning {
                Text(warning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
        let card = ShareCardView(
            phototype: phototype,
            streak: currentStreak,
            unlockedBadges: unlockedBadges,
            totalVitaminDIU: totalVitaminD
        )
        guard let image = card.renderedImage() else {
            gameCenterWarning = String(localized: "Impossibile generare l'immagine da condividere.")
            return
        }
        shareImage = ShareImage(image: image)
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

private struct ShareImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
