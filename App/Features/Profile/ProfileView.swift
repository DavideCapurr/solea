import SwiftUI
import SwiftData
import SoleaCore

struct ProfileView: View {
    let phototype: Fitzpatrick

    @Environment(\.modelContext) private var modelContext
    @State private var showResetConfirmation = false
    @State private var resetErrorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("La tua pelle") {
                    HStack {
                        Text("Fototipo")
                        Spacer()
                        Text(phototype.romanNumeral)
                            .bold()
                            .foregroundStyle(.orange)
                    }
                    Text(LocalizedStringKey(phototype.summaryKey))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("Dose massima (MED)")
                        Spacer()
                        Text("\(Int(phototype.med)) J/m²")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Rifai il quiz", role: .destructive) {
                        showResetConfirmation = true
                    }
                } footer: {
                    Text("Il fototipo determina i tempi di esposizione sicura: rifai il quiz se pensi che non ti rappresenti.")
                }
            }
            .navigationTitle("Profilo")
            .confirmationDialog(
                "Vuoi rifare il quiz del fototipo?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Rifai il quiz", role: .destructive) { resetProfile() }
                Button("Annulla", role: .cancel) {}
            }
            .alert(
                "Operazione non riuscita",
                isPresented: Binding(
                    get: { resetErrorMessage != nil },
                    set: { if !$0 { resetErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resetErrorMessage ?? "")
            }
        }
    }

    private func resetProfile() {
        do {
            try modelContext.delete(model: UserProfile.self)
            try modelContext.save()
            // RootView osserva i profili: senza profilo torna all'onboarding.
        } catch {
            resetErrorMessage = error.localizedDescription
        }
    }
}
