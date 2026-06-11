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
                        row(session: session)
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
                Label(
                    session.averageUVIndex.formatted(.number.precision(.fractionLength(1))),
                    systemImage: "sun.max"
                )
                if let fraction = session.fractionOfMED {
                    Label(
                        fraction.formatted(.percent.precision(.fractionLength(0))),
                        systemImage: "gauge.with.needle"
                    )
                    .foregroundStyle(fraction < 0.8 ? Color.secondary : .red)
                }
                Label("≈ \(Int(session.vitaminDIU)) IU", systemImage: "pills")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let minutes = Int((duration / 60).rounded())
        if minutes >= 60 {
            return String(localized: "\(minutes / 60) h \(minutes % 60) min")
        }
        return String(localized: "\(minutes) min")
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
