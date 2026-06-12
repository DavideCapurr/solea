import SwiftUI
import SwiftData
import SoleaCore

struct CoachView: View {
    let phototype: Fitzpatrick
    /// UV attuale se già noto dalla schermata Oggi (può essere nil).
    let currentUVIndex: Double?

    @Query private var sessions: [TanSession]
    @State private var viewModel = CoachViewModel()

    private var context: CoachContext {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let records = sessions.map {
            SessionRecord(day: $0.startedAt, fractionOfMED: $0.fractionOfMED ?? 0, vitaminDIU: $0.vitaminDIU)
        }
        return CoachContext(
            phototype: phototype,
            currentUVIndex: currentUVIndex,
            todaySessionCount: sessions.filter { $0.startedAt >= startOfDay }.count,
            currentStreak: Streaks.currentStreak(records: records, today: .now)
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isAvailable {
                    chat
                } else {
                    ContentUnavailableView {
                        Label("Coach non disponibile", systemImage: "bubble.left.and.exclamationmark.bubble.right")
                    } description: {
                        Text("Il Coach richiede il modello on-device (iOS 26+) oppure la configurazione del proxy Claude.")
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
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
