import SwiftUI
import Charts
import SoleaCore

struct TodayView: View {
    let phototype: Fitzpatrick

    @State private var viewModel = TodayViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView("Caricamento dati UV…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed(let message):
                    ContentUnavailableView {
                        Label("Dati UV non disponibili", systemImage: "sun.max.trianglebadge.exclamationmark")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Riprova") {
                            Task { await viewModel.load(phototype: phototype) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                case .loaded(let metrics):
                    content(metrics: metrics)
                }
            }
            .navigationTitle("Oggi")
            .task { await viewModel.load(phototype: phototype) }
            .refreshable { await viewModel.load(phototype: phototype) }
        }
    }

    private func content(metrics: TodayMetrics) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                uvCard(metrics: metrics)
                safeTimeCard(metrics: metrics)
                goldenHoursCard(metrics: metrics)
                forecastCard(metrics: metrics)
                sessionCTA
            }
            .padding()
        }
    }

    // MARK: - UV attuale + burn risk

    private func uvCard(metrics: TodayMetrics) -> some View {
        card {
            HStack(spacing: 24) {
                Gauge(value: min(metrics.conditions.currentUVIndex, 11), in: 0...11) {
                    Text("UV")
                } currentValueLabel: {
                    Text(metrics.conditions.currentUVIndex, format: .number.precision(.fractionLength(0)))
                        .font(.title2.bold())
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [.green, .yellow, .orange, .red, .purple]))
                .scaleEffect(1.3)
                .frame(width: 90, height: 90)

                VStack(alignment: .leading, spacing: 6) {
                    Text("UV attuale")
                        .font(.headline)
                    Label(riskLabel(metrics.burnRisk), systemImage: "circle.fill")
                        .foregroundStyle(riskColor(metrics.burnRisk))
                        .font(.subheadline.bold())
                    Text("Fototipo \(phototype.romanNumeral)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    private func riskLabel(_ risk: BurnRisk) -> LocalizedStringKey {
        switch risk {
        case .low: return "Rischio scottatura basso"
        case .moderate: return "Rischio scottatura moderato"
        case .high: return "Rischio scottatura alto"
        }
    }

    private func riskColor(_ risk: BurnRisk) -> Color {
        switch risk {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .red
        }
    }

    // MARK: - Tempo sicuro

    private func safeTimeCard(metrics: TodayMetrics) -> some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tempo sicuro al sole")
                    .font(.headline)
                HStack {
                    safeTimeColumn(title: "Senza protezione", minutes: metrics.safeMinutesBareSkin)
                    Divider()
                    safeTimeColumn(title: "Con SPF 30", minutes: metrics.safeMinutesSPF30)
                }
            }
        }
    }

    private func safeTimeColumn(title: LocalizedStringKey, minutes: Double) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formattedMinutes(minutes))
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity)
    }

    private func formattedMinutes(_ minutes: Double) -> String {
        if minutes.isInfinite {
            return String(localized: "Illimitato")
        }
        if minutes >= 120 {
            let hours = minutes / 60
            return String(localized: "\(hours.formatted(.number.precision(.fractionLength(0...1)))) h")
        }
        return String(localized: "\(Int(minutes.rounded())) min")
    }

    // MARK: - Golden hours

    private func goldenHoursCard(metrics: TodayMetrics) -> some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Label("Golden hours", systemImage: "sparkles")
                    .font(.headline)
                if metrics.goldenHours.isEmpty {
                    Text("Nessuna finestra ideale nelle prossime 24 ore per il tuo fototipo.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(metrics.goldenHours, id: \.self) { window in
                        HStack {
                            Image(systemName: "sun.haze.fill")
                                .foregroundStyle(.orange)
                            Text(intervalText(window))
                                .font(.subheadline.monospacedDigit())
                        }
                    }
                    Text("Le fasce in cui ti abbronzi bene con il minor rischio per il tuo fototipo.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func intervalText(_ interval: DateInterval) -> String {
        let start = interval.start.formatted(date: .omitted, time: .shortened)
        let end = interval.end.formatted(date: .omitted, time: .shortened)
        return "\(start) – \(end)"
    }

    // MARK: - Previsione oraria

    private func forecastCard(metrics: TodayMetrics) -> some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Previsione UV")
                    .font(.headline)
                Chart(metrics.conditions.hourly.prefix(12), id: \.date) { hour in
                    BarMark(
                        x: .value("Ora", hour.date, unit: .hour),
                        y: .value("UV", hour.uvIndex)
                    )
                    .foregroundStyle(barColor(uv: hour.uvIndex))
                }
                .chartYScale(domain: 0...11)
                .frame(height: 160)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func barColor(uv: Double) -> Color {
        switch uv {
        case ..<3: return .green
        case ..<6: return .yellow
        case ..<8: return .orange
        case ..<11: return .red
        default: return .purple
        }
    }

    // MARK: - CTA sessione (arriva in M2)

    private var sessionCTA: some View {
        VStack(spacing: 8) {
            Button {
                // M2: avvio del timer di sessione.
            } label: {
                Label("Inizia sessione", systemImage: "timer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(true)
            Text("Il timer di sessione arriva con la prossima milestone.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func card(@ViewBuilder content: () -> some View) -> some View {
        content()
            .padding()
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
