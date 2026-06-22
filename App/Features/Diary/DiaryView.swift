import SwiftUI
import SwiftData
import SoleaCore

struct DiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TanSession.startedAt, order: .reverse) private var sessions: [TanSession]
    @State private var deleteErrorMessage: String?

    var body: some View {
        NavigationStack {
            list
            .navigationTitle("Diario")
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
    }

    private var list: some View {
        List {
            Section("Questa settimana") {
                weeklyStats
            }
            Section {
                NavigationLink {
                    PhotoDiaryView()
                } label: {
                    Label("Foto-diario del tan", systemImage: "camera")
                }
            }
            Section("Sessioni") {
                if sessions.isEmpty {
                    Text("Avvia la tua prima sessione dalla schermata Oggi: la troverai qui.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sessions) { session in
                        NavigationLink {
                            sessionDetail(session)
                        } label: {
                            row(session: session)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
        }
    }

    private var weeklyStats: some View {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        let weekSessions = sessions.filter { $0.startedAt >= weekStart }
        let totalMinutes = Int(weekSessions.reduce(0) { $0 + $1.duration } / 60)
        let totalVitaminD = Int(weekSessions.reduce(0) { $0 + $1.vitaminDIU })

        return Group {
            LabeledContent("Sessioni") { Text("\(weekSessions.count)") }
            LabeledContent("Tempo al sole") {
                Text(totalMinutes >= 60
                     ? String(localized: "\(totalMinutes / 60) h \(totalMinutes % 60) min")
                     : String(localized: "\(totalMinutes) min"))
            }
            LabeledContent("Vitamina D stimata") { Text("≈ \(totalVitaminD) IU") }
        }
    }

    private func row(session: TanSession) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.headline)
                Spacer()
                Text(durationText(session.duration))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                Label(goalTitle(session.goal), systemImage: "target")
                Label(
                    session.averageUVIndex.formatted(.number.precision(.fractionLength(1))),
                    systemImage: "sun.max"
                )
                if let fraction = session.fractionOfMED {
                    Label(
                        fraction.formatted(.percent.precision(.fractionLength(0))),
                        systemImage: "gauge.with.needle"
                    )
                    .foregroundStyle(fraction < SafeExposure.recommendedLimitFractionOfMED ? Color.secondary : .red)
                }
                Label("≈ \(Int(session.vitaminDIU)) IU", systemImage: "pills")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                if session.plannedMinutes > 0 {
                    Label("\(session.plannedMinutes) min target", systemImage: "timer")
                }
                if session.pauseSeconds > 0 {
                    Label("\(durationText(seconds: session.pauseSeconds)) pausa", systemImage: "pause.circle")
                }
                Label(sideSplitText(session), systemImage: "arrow.left.and.right")
                if session.skinResponse != .notLogged {
                    Label(skinResponseTitle(session.skinResponse), systemImage: "hand.raised")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
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
                    LabeledContent("Target") {
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
        .navigationTitle(session.startedAt.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let minutes = Int((duration / 60).rounded())
        if minutes >= 60 {
            return String(localized: "\(minutes / 60) h \(minutes % 60) min")
        }
        return String(localized: "\(minutes) min")
    }

    private func durationText(seconds: Int) -> String {
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
        case .gradualTan: return "Tan graduale"
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

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
        do {
            try modelContext.save()
        } catch {
            deleteErrorMessage = error.localizedDescription
        }
    }
}
