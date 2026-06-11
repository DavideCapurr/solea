import SwiftUI
import SwiftData
import SoleaCore

struct PlannerView: View {
    let phototype: Fitzpatrick

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VacationPlan.createdAt, order: .reverse) private var plans: [VacationPlan]
    @State private var showNewPlan = false

    var body: some View {
        NavigationStack {
            Group {
                if plans.isEmpty {
                    ContentUnavailableView {
                        Label("Nessun piano", systemImage: "airplane.departure")
                    } description: {
                        Text("Crea un piano per arrivare in vacanza già preparato, senza scottarti.")
                    } actions: {
                        Button("Nuovo piano") { showNewPlan = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    planList
                }
            }
            .navigationTitle("Planner")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewPlan = true
                    } label: {
                        Label("Nuovo piano", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewPlan) {
                NewPlanView(phototype: phototype)
            }
        }
    }

    private var planList: some View {
        List {
            ForEach(plans) { plan in
                NavigationLink {
                    PlanDetailView(plan: plan)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.destinationName)
                            .font(.headline)
                        Text("Partenza \(plan.departureDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: delete)
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(plans[index])
        }
        // L'eventuale errore di save emerge al prossimo accesso; qui la delete
        // in memoria è già riflessa dalla @Query.
        try? modelContext.save()
    }
}

private struct PlanDetailView: View {
    let plan: VacationPlan

    var body: some View {
        List {
            switch Result(catching: { try plan.days() }) {
            case .success(let days):
                Section("Esposizione giorno per giorno") {
                    ForEach(days) { day in
                        HStack {
                            Text(day.date.formatted(date: .abbreviated, time: .omitted))
                            Spacer()
                            Text("\(day.minutes) min · SPF \(day.spf)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            case .failure(let error):
                Section {
                    Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(plan.destinationName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
