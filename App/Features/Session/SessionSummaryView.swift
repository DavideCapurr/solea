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
                    LabeledContent("Quota della dose massima") {
                        Text(session.fractionOfMED, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(session.fractionOfMED < 0.8 ? .primary : Color.red)
                    }
                    LabeledContent("Vitamina D stimata") {
                        Text("≈ \(Int(session.vitaminDIU.rounded())) IU")
                    }
                }

                Section {
                    Text(session.fractionOfMED < 0.8
                         ? "Bella sessione! Sei rimasto sotto la soglia di sicurezza."
                         : "Hai sfiorato la dose massima: domani concedi una pausa alla tua pelle e idratati bene.")
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
