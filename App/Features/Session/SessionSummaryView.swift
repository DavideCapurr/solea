import SwiftUI
import SoleaCore

struct SessionSummaryView: View {
    let session: FinishedSession

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Riepilogo") {
                    LabeledContent("Durata") {
                        Text(durationText)
                    }
                    LabeledContent("UV medio") {
                        Text(session.averageUVIndex, format: .number.precision(.fractionLength(1)))
                    }
                    LabeledContent("Dose UV assorbita") {
                        Text("\(Int(session.effectiveDose.rounded())) J/m²")
                    }
                    LabeledContent("Quota della MED") {
                        Text(session.fractionOfMED, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(session.fractionOfMED < SafeExposure.recommendedLimitFractionOfMED ? .primary : Color.red)
                    }
                    LabeledContent("Vitamina D stimata") {
                        Text("≈ \(Int(session.vitaminDIU.rounded())) IU")
                    }
                }

                Section {
                    Text(session.fractionOfMED < SafeExposure.recommendedLimitFractionOfMED
                         ? "Bella sessione: sei rimasto sotto la soglia prudente."
                         : "Hai raggiunto la soglia prudente: concedi una pausa alla pelle e resta all'ombra.")
                    .font(.subheadline)
                }
            }
            .navigationTitle("Sessione completata")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
            }
        }
    }

    private var durationText: String {
        let minutes = Int((session.duration / 60).rounded())
        if minutes >= 60 {
            return String(localized: "\(minutes / 60) h \(minutes % 60) min")
        }
        return String(localized: "\(minutes) min")
    }
}
