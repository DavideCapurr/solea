import SwiftUI
import WidgetKit
import ActivityKit

/// Live Activity della sessione: lock screen e Dynamic Island.
struct SessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack {
                        Text("UV")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.state.currentUVIndex, format: .number.precision(.fractionLength(0)))
                            .font(.title2.bold())
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(elapsedText(context.state.elapsedSeconds))
                            .font(.title3.bold().monospacedDigit())
                        Text("Fototipo \(context.attributes.phototypeRoman)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    doseGauge(fraction: context.state.doseFraction)
                        .frame(width: 44, height: 44)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(remainingText(context.state))
                        .font(.caption)
                        .foregroundStyle(context.state.doseFraction >= 1 ? .red : .secondary)
                }
            } compactLeading: {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                Text(context.state.doseFraction, format: .percent.precision(.fractionLength(0)))
                    .font(.caption2.bold())
                    .foregroundStyle(context.state.doseFraction < 0.8 ? .primary : Color.red)
            } minimal: {
                doseGauge(fraction: context.state.doseFraction)
            }
        }
    }

    private func lockScreenView(context: ActivityViewContext<SessionActivityAttributes>) -> some View {
        HStack(spacing: 16) {
            doseGauge(fraction: context.state.doseFraction)
                .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text("Sessione in corso")
                    .font(.headline)
                Text(elapsedText(context.state.elapsedSeconds))
                    .font(.title3.bold().monospacedDigit())
                Text(remainingText(context.state))
                    .font(.caption)
                    .foregroundStyle(context.state.doseFraction >= 1 ? .red : .secondary)
            }
            Spacer()
            VStack {
                Text("UV")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(context.state.currentUVIndex, format: .number.precision(.fractionLength(0)))
                    .font(.title2.bold())
            }
        }
        .padding()
        .activityBackgroundTint(Color(.systemBackground).opacity(0.8))
    }

    private func doseGauge(fraction: Double) -> some View {
        Gauge(value: min(fraction, 1)) {
            Image(systemName: "sun.max.fill")
        } currentValueLabel: {
            Text(fraction, format: .percent.precision(.fractionLength(0)))
                .font(.caption2.bold())
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(fraction < 0.5 ? .green : (fraction < 0.8 ? .yellow : .red))
    }

    private func elapsedText(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    private func remainingText(_ state: SessionActivityAttributes.ContentState) -> String {
        guard let remaining = state.remainingSafeSeconds else {
            return String(localized: "UV basso: nessun limite di tempo")
        }
        if remaining <= 0 {
            return String(localized: "Limite prudente esaurito — all'ombra!")
        }
        let minutes = Int((remaining / 60).rounded())
        return String(localized: "Ancora \(minutes) min nel limite prudente")
    }
}
