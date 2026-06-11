import SwiftUI
import SwiftData
import SoleaCore

struct NewPlanView: View {
    let phototype: Fitzpatrick

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PlannerViewModel()
    @State private var saveErrorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Destinazione") {
                    TextField("Città o località", text: $viewModel.destinationQuery)
                        .textInputAutocapitalization(.words)
                    DatePicker(
                        "Partenza",
                        selection: $viewModel.departureDate,
                        in: Date.now...,
                        displayedComponents: .date
                    )
                }

                Section {
                    if viewModel.preparationDays() < TanPlanner.preparationDaysRange.lowerBound {
                        Label("Scegli una data di partenza ad almeno un giorno da oggi.",
                              systemImage: "calendar.badge.exclamationmark")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if viewModel.preparationDays() > TanPlanner.preparationDaysRange.upperBound {
                        Label("Il piano copre al massimo \(TanPlanner.preparationDaysRange.upperBound) giorni di preparazione.",
                              systemImage: "calendar.badge.exclamationmark")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        LabeledContent("Giorni di preparazione") {
                            Text("\(viewModel.preparationDays())")
                        }
                    }
                }

                if case .failed(let message) = viewModel.generationState {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Nuovo piano")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.generationState == .loading {
                        ProgressView()
                    } else {
                        Button("Crea") { generate() }
                            .disabled(!viewModel.canGenerate)
                    }
                }
            }
            .alert(
                "Salvataggio non riuscito",
                isPresented: Binding(
                    get: { saveErrorMessage != nil },
                    set: { if !$0 { saveErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? "")
            }
        }
    }

    private func generate() {
        Task {
            guard let (destination, plan) = await viewModel.generate(phototype: phototype) else {
                return
            }
            do {
                let stored = plan.map {
                    StoredPlanDay(id: $0.id, date: $0.date, minutes: $0.minutes, spf: $0.spf)
                }
                let model = try VacationPlan(
                    destinationName: destination.resolvedName,
                    departureDate: viewModel.departureDate,
                    expectedUVIndex: destination.expectedPeakUVIndex,
                    phototypeRawValue: phototype.rawValue,
                    days: stored
                )
                modelContext.insert(model)
                try modelContext.save()
                dismiss()
            } catch {
                saveErrorMessage = error.localizedDescription
            }
        }
    }
}
