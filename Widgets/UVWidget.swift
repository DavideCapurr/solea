import SwiftUI
import WidgetKit
import SoleaCore

/// Stato mostrato dal widget. Il widget non interroga WeatherKit: legge la
/// snapshot scritta dall'app e dichiara apertamente dati mancanti o vecchi.
enum UVWidgetData {
    case fresh(UVSnapshot)
    case stale(UVSnapshot)
    case missing
    case error(String)
}

struct UVWidgetEntry: TimelineEntry {
    let date: Date
    let data: UVWidgetData
}

struct UVWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> UVWidgetEntry {
        UVWidgetEntry(
            date: .now,
            data: .fresh(UVSnapshot(
                currentUVIndex: 6,
                safeMinutesBareSkin: 25,
                burnRiskRawValue: BurnRisk.moderate.rawValue,
                phototypeRawValue: Fitzpatrick.typeIII.rawValue,
                updatedAt: .now
            ))
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (UVWidgetEntry) -> Void) {
        completion(UVWidgetEntry(date: .now, data: currentData()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UVWidgetEntry>) -> Void) {
        let entry = UVWidgetEntry(date: .now, data: currentData())
        // L'app riscrive la snapshot a ogni apertura; il widget ricontrolla
        // comunque ogni 30 minuti per aggiornare lo stato di anzianità.
        completion(Timeline(
            entries: [entry],
            policy: .after(.now.addingTimeInterval(30 * 60))
        ))
    }

    private func currentData() -> UVWidgetData {
        do {
            guard let snapshot = try SharedStore.loadSnapshot() else { return .missing }
            return snapshot.isStale ? .stale(snapshot) : .fresh(snapshot)
        } catch {
            return .error(error.localizedDescription)
        }
    }
}

struct UVWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: UVWidgetEntry

    var body: some View {
        content
            .containerBackground(.background, for: .widget)
    }

    @ViewBuilder
    private var content: some View {
        switch entry.data {
        case .fresh(let snapshot):
            snapshotView(snapshot, stale: false)
        case .stale(let snapshot):
            snapshotView(snapshot, stale: true)
        case .missing:
            messageView("Apri Solea per caricare i dati UV.")
        case .error(let message):
            messageView(message)
        }
    }

    @ViewBuilder
    private func snapshotView(_ snapshot: UVSnapshot, stale: Bool) -> some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: min(snapshot.currentUVIndex, 11), in: 0...11) {
                Text("UV")
            } currentValueLabel: {
                Text(snapshot.currentUVIndex, format: .number.precision(.fractionLength(0)))
            }
            .gaugeStyle(.accessoryCircular)
            .opacity(stale ? 0.5 : 1)

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("UV \(snapshot.currentUVIndex.formatted(.number.precision(.fractionLength(0))))")
                    .font(.headline)
                Text(safeTimeText(snapshot))
                    .font(.caption)
                if stale {
                    Text("Dati non aggiornati")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

        default:
            VStack(spacing: 6) {
                Gauge(value: min(snapshot.currentUVIndex, 11), in: 0...11) {
                    Text("UV")
                } currentValueLabel: {
                    Text(snapshot.currentUVIndex, format: .number.precision(.fractionLength(0)))
                        .font(.title3.bold())
                }
                .gaugeStyle(.accessoryCircular)
                .tint(riskColor(snapshot))
                Text(safeTimeText(snapshot))
                    .font(.caption)
                Text(stale
                     ? "Dati non aggiornati"
                     : snapshot.updatedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func messageView(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
    }

    private func safeTimeText(_ snapshot: UVSnapshot) -> String {
        if snapshot.safeMinutesBareSkin.isInfinite {
            return String(localized: "Senza limiti di tempo")
        }
        return String(localized: "\(Int(snapshot.safeMinutesBareSkin.rounded())) min senza crema")
    }

    private func riskColor(_ snapshot: UVSnapshot) -> Color {
        switch BurnRisk(rawValue: snapshot.burnRiskRawValue) {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .red
        case nil: return .gray
        }
    }
}

struct UVWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "UVWidget", provider: UVWidgetProvider()) { entry in
            UVWidgetView(entry: entry)
        }
        .configurationDisplayName("UV adesso")
        .description("Indice UV attuale e tempo sicuro per il tuo fototipo.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}
