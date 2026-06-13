import SwiftUI
import SoleaCore

/// Schermata principale al polso: UV a colpo d'occhio, tempo sicuro per il
/// fototipo scelto e un timer di sessione rapido con haptic.
struct WatchRootView: View {
    enum State {
        case loading
        case loaded(uvIndex: Double)
        case failed(String)
    }

    // Il Watch non ha (ancora) il profilo sincronizzato: si sceglie il fototipo
    // qui. La sincronizzazione del profilo via WatchConnectivity è un'estensione
    // futura, annotata in PROGRESS.
    @AppStorage("watch.phototype") private var phototypeRaw = Fitzpatrick.typeIII.rawValue
    @State private var state: State = .loading

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
        .task { await load() }
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
            WatchSessionView(phototype: phototype, uvIndex: uvIndex)
        } label: {
            Label("Sessione", systemImage: "timer")
        }
    }

    private func load() async {
        state = .loading
        do {
            let uv = try await service.currentUV()
            state = .loaded(uvIndex: uv.uvIndex)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
