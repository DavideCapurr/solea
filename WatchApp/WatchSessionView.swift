import SwiftUI
import WatchKit
import SoleaCore

/// Timer di sessione al polso: integra la dose e dà un feedback haptic ai
/// promemoria "girati" e quando il limite prudente si esaurisce.
struct WatchSessionView: View {
    let phototype: Fitzpatrick
    let uvIndex: Double
    let hasSoleaPlus: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var elapsedSeconds = 0
    @State private var effectiveDose = 0.0
    @State private var running = false
    @State private var safetyAlerted = false
    @State private var timerTask: Task<Void, Never>?

    private let spf: Double = 30
    private let flipIntervalSeconds = 20 * 60

    private var doseFraction: Double {
        effectiveDose / phototype.med
    }

    var body: some View {
        VStack(spacing: 10) {
            Gauge(value: min(doseFraction, 1)) {
                Text("Dose")
            } currentValueLabel: {
                Text(doseFraction, format: .percent.precision(.fractionLength(0)))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(doseFraction < 0.8 ? .green : .red)

            Text(elapsedText)
                .font(.title3.monospacedDigit())

            if !hasSoleaPlus {
                Text("Timer base. Sblocca Solea Plus su iPhone per haptic promemoria e metriche avanzate.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(running ? String(localized: "Pausa") : String(localized: "Avvia")) {
                running ? pause() : start()
            }
            .tint(running ? .orange : .green)

            Button("Termina") {
                pause()
                dismiss()
            }
            .tint(.red)
        }
        .padding()
        .navigationTitle("Sessione")
        .onDisappear { timerTask?.cancel() }
    }

    private var elapsedText: String {
        String(format: "%d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
    }

    private func start() {
        running = true
        timerTask?.cancel()
        timerTask = Task {
            while running {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
                tick()
            }
        }
    }

    private func pause() {
        running = false
        timerTask?.cancel()
        timerTask = nil
    }

    private func tick() {
        elapsedSeconds += 1
        effectiveDose += uvIndex * SafeExposure.wattsPerUVIndexUnit / spf

        if hasSoleaPlus && elapsedSeconds % flipIntervalSeconds == 0 {
            WKInterfaceDevice.current().play(.notification)
        }
        if !safetyAlerted && doseFraction >= 1 {
            safetyAlerted = true
            WKInterfaceDevice.current().play(.failure)
        }
    }
}
