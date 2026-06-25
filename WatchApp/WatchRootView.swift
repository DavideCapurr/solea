import SwiftUI
import SoleaCore

/// Schermata principale al polso: UV a colpo d'occhio, limite prudente per il
/// fototipo scelto e un timer di sessione rapido con haptic.
struct WatchRootView: View {
    enum ViewState {
        case loading
        case loaded(uvIndex: Double)
        case failed(String)
    }

    // Il fototipo arriva dall'iPhone via WatchConnectivity (`WatchProfileSync`
    // scrive su questa stessa chiave). Il picker resta come override locale e
    // come fallback finché non arriva la prima sincronizzazione.
    @AppStorage("watch.phototype") private var phototypeRaw = Fitzpatrick.typeIII.rawValue
    @AppStorage("watch.soleaPlusActive") private var hasSoleaPlus = false
    @State private var state: ViewState = .loading
    @State private var profileSync = WatchProfileSync()

    private let service = WatchUVService()

    private var phototype: Fitzpatrick {
        Fitzpatrick(rawValue: phototypeRaw) ?? .typeIII
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    switch state {
                    case .loading:
                        ProgressView()
                    case .loaded(let uvIndex):
                        loaded(uvIndex: uvIndex)
                    case .failed(let message):
                        VStack(spacing: 8) {
                            Text(message)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                            Button("Riprova") { Task { await load() } }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Solea")
        }
        .task {
            profileSync.activate()
            await load()
        }
    }

    @ViewBuilder
    private func loaded(uvIndex: Double) -> some View {
        Gauge(value: min(uvIndex, 11), in: 0...11) {
            Text("UV")
        } currentValueLabel: {
            Text(uvIndex, format: .number.precision(.fractionLength(0)))
                .font(.title2.bold())
        }
        .gaugeStyle(.accessoryCircular)
        .tint(Gradient(colors: [.green, .yellow, .orange, .red]))

        switch Result(catching: { try SafeExposure.minutes(phototype: phototype, uvIndex: uvIndex) }) {
        case .success(let minutes):
            Text(minutes.isInfinite
                 ? String(localized: "Tempo illimitato")
                 : String(localized: "\(Int(minutes.rounded())) min senza crema"))
            .font(.footnote)
            .multilineTextAlignment(.center)
        case .failure(let error):
            Text(error.localizedDescription)
                .font(.caption2)
                .foregroundStyle(.red)
        }

        Picker("Fototipo", selection: $phototypeRaw) {
            ForEach(Fitzpatrick.allCases) { type in
                Text(type.romanNumeral).tag(type.rawValue)
            }
        }
        .frame(height: 60)

        NavigationLink {
            WatchSessionView(
                phototype: phototype,
                uvIndex: uvIndex,
                hasSoleaPlus: hasSoleaPlus
            )
        } label: {
            Label("Sessione", systemImage: "timer")
        }
    }

    private func load() async {
        state = .loading
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-soleaScreenshotDemo") {
            state = .loaded(uvIndex: 6.4)
            return
        }
        #endif
        do {
            let uv = try await service.currentUV()
            state = .loaded(uvIndex: uv.uvIndex)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
