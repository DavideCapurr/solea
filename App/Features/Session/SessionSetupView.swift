import SwiftUI
import SoleaCore

struct SessionSetupView: View {
    let currentUVIndex: Double
    let phototype: Fitzpatrick
    let onStart: (SessionConfiguration) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var spf: Double = 30
    @State private var zones: ExposedZones = [.torso, .back, .arms, .legs]
    @State private var flipIntervalMinutes = 20

    private static let spfOptions: [Double] = [1, 6, 10, 15, 20, 30, 50]
    private static let flipOptions = [15, 20, 30, 45]

    var body: some View {
        NavigationStack {
            Form {
                Section("Protezione") {
                    Picker("SPF applicato", selection: $spf) {
                        ForEach(Self.spfOptions, id: \.self) { value in
                            if value == 1 {
                                Text("Nessuna").tag(value)
                            } else {
                                Text("SPF \(Int(value))").tag(value)
                            }
                        }
                    }
                }

                Section("Zone esposte") {
                    zoneToggle("Viso", zone: .face)
                    zoneToggle("Petto", zone: .torso)
                    zoneToggle("Schiena", zone: .back)
                    zoneToggle("Braccia", zone: .arms)
                    zoneToggle("Gambe", zone: .legs)
                }

                Section("Promemoria") {
                    Picker("Girati ogni", selection: $flipIntervalMinutes) {
                        ForEach(Self.flipOptions, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                }

                Section {
                    recommendedLimitPreview
                } footer: {
                    Text("Stimato per il tuo fototipo \(phototype.romanNumeral) all'UV attuale; si aggiorna se l'UV cambia.")
                }
            }
            .navigationTitle("Nuova sessione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Avvia") {
                        onStart(SessionConfiguration(
                            spf: spf,
                            zones: zones,
                            flipIntervalMinutes: flipIntervalMinutes
                        ))
                        dismiss()
                    }
                    .disabled(zones.isEmpty)
                }
            }
        }
    }

    private func zoneToggle(_ title: LocalizedStringKey, zone: ExposedZones) -> some View {
        Toggle(title, isOn: Binding(
            get: { zones.contains(zone) },
            set: { isOn in
                if isOn { zones.insert(zone) } else { zones.remove(zone) }
            }
        ))
    }

    @ViewBuilder
    private var recommendedLimitPreview: some View {
        switch Result(catching: {
            try SafeExposure.minutes(phototype: phototype, uvIndex: currentUVIndex, spf: spf)
        }) {
        case .success(let minutes):
            LabeledContent("Limite prudente stimato") {
                Text(minutes.isInfinite
                     ? String(localized: "UV trascurabile")
                     : String(localized: "\(Int(minutes.rounded())) min"))
                .bold()
            }
        case .failure(let error):
            // UV o SPF invalidi non vanno mascherati con un numero plausibile.
            Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
        }
    }
}
