import SwiftUI
import SoleaCore

struct ActiveSessionView: View {
    let manager: SessionManager
    let onEnd: () -> Void

    var body: some View {
        Group {
            if let session = manager.active {
                content(session: session)
            } else {
                // Stato transitorio tra end() e l'aggiornamento del parent.
                ProgressView()
            }
        }
    }

    private func content(session: SessionManager.ActiveSession) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                doseRing(session: session)

                LabeledContent("Tempo trascorso") {
                    Text(formattedElapsed(session.elapsedSeconds))
                        .font(.title3.bold().monospacedDigit())
                }
                LabeledContent("UV attuale") {
                    Text(session.currentUVIndex, format: .number.precision(.fractionLength(0)))
                        .bold()
                }
                LabeledContent("Tempo sicuro rimanente") {
                    remainingLabel
                }
                LabeledContent("SPF") {
                    Text(session.configuration.spf == 1
                         ? String(localized: "Nessuna")
                         : "SPF \(Int(session.configuration.spf))")
                }

                warnings

                Button(role: .destructive) {
                    onEnd()
                } label: {
                    Label("Termina sessione", systemImage: "stop.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .navigationTitle("Sessione in corso")
    }

    private func doseRing(session: SessionManager.ActiveSession) -> some View {
        let fraction = min(session.effectiveDose / session.phototype.med, 1)
        return Gauge(value: fraction) {
            Text("Dose UV")
        } currentValueLabel: {
            VStack {
                Text(fraction, format: .percent.precision(.fractionLength(0)))
                    .font(.title.bold())
                Text("della dose massima")
                    .font(.caption2)
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(fraction < 0.5 ? .green : (fraction < 0.8 ? .yellow : .red))
        .scaleEffect(2.2)
        .frame(width: 180, height: 180)
        .padding(.top, 24)
    }

    @ViewBuilder
    private var remainingLabel: some View {
        if let remaining = manager.remainingSafeSeconds {
            if remaining <= 0 {
                Text("Esaurito — mettiti all'ombra")
                    .bold()
                    .foregroundStyle(.red)
            } else if remaining.isInfinite {
                Text("Illimitato")
            } else {
                Text(formattedElapsed(Int(remaining)))
                    .bold()
                    .monospacedDigit()
            }
        }
    }

    @ViewBuilder
    private var warnings: some View {
        VStack(spacing: 8) {
            if let warning = manager.uvRefreshWarning {
                warningLabel(
                    String(localized: "Aggiornamento UV non riuscito (uso l'ultimo valore noto): \(warning)")
                )
            }
            if let warning = manager.reminderWarning {
                warningLabel(warning)
            }
        }
    }

    private func warningLabel(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    private func formattedElapsed(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}
