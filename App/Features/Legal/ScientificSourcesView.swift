import SwiftUI

/// Fonti scientifiche delle stime mostrate da Tanora (indice UV, fototipo, limite
/// prudente, SPF, vitamina D). Richiesta dalla linea guida App Store 1.4.1:
/// le informazioni di salute devono citare fonti facili da trovare.
struct ScientificSourcesView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Source: Identifiable {
        let id = UUID()
        let title: String
        let publisher: String
        let url: URL

        init(_ title: String, _ publisher: String, _ urlString: String) {
            self.title = title
            self.publisher = publisher
            self.url = URL(string: urlString)!
        }
    }

    private struct Topic: Identifiable {
        let id = UUID()
        let header: LocalizedStringKey
        let footer: LocalizedStringKey
        let sources: [Source]
    }

    private let topics: [Topic] = [
        Topic(
            header: "Indice UV e rischio scottatura",
            footer: "Tanora usa l'indice UV per stimare il rischio di scottatura e le ore più prudenti.",
            sources: [
                Source(
                    "Global Solar UV Index: A Practical Guide",
                    "World Health Organization (OMS)",
                    "https://www.who.int/publications/i/item/9241590076"
                ),
                Source(
                    "A Guide to the UV Index",
                    "U.S. EPA / National Weather Service",
                    "https://www.epa.gov/sites/default/files/documents/uviguide.pdf"
                )
            ]
        ),
        Topic(
            header: "Fototipo (scala Fitzpatrick)",
            footer: "Il quiz iniziale stima il tuo fototipo Fitzpatrick, base dei limiti personalizzati.",
            sources: [
                Source(
                    "Skin phototype",
                    "DermNet",
                    "https://dermnetnz.org/topics/skin-phototype"
                )
            ]
        ),
        Topic(
            header: "Limite prudente, MED e dose eritemale",
            footer: "Il limite prudente resta sotto la dose minima eritemale (MED), misurata in dose eritemale standard (SED).",
            sources: [
                Source(
                    "Health Issues of Ultraviolet Tanning Appliances",
                    "ICNIRP",
                    "https://www.icnirp.org/cms/upload/publications/ICNIRPsunbed.pdf"
                ),
                Source(
                    "Standard Erythema Dose: A Review",
                    "CIE",
                    "https://cie.co.at/publications/standard-erythema-dose-review"
                )
            ]
        ),
        Topic(
            header: "SPF e protezione solare",
            footer: "Lo SPF attenua la dose stimata, ma non moltiplica liberamente il tempo al sole.",
            sources: [
                Source(
                    "Sun Protection Factor (SPF)",
                    "U.S. Food and Drug Administration",
                    "https://www.fda.gov/about-fda/center-drug-evaluation-and-research-cder/sun-protection-factor-spf"
                ),
                Source(
                    "Sunscreen: How to Help Protect Your Skin from the Sun",
                    "U.S. Food and Drug Administration",
                    "https://www.fda.gov/drugs/understanding-over-counter-medicines/sunscreen-how-help-protect-your-skin-sun"
                )
            ]
        ),
        Topic(
            header: "Stima della vitamina D",
            footer: "La vitamina D è una stima euristica: non sostituisce l'esame del 25(OH)D nel sangue.",
            sources: [
                Source(
                    "Vitamin D — Fact Sheet for Health Professionals",
                    "NIH Office of Dietary Supplements",
                    "https://ods.od.nih.gov/factsheets/VitaminD-HealthProfessional/"
                ),
                Source(
                    "Vitamin D: importance for skin and sunlight exposure",
                    "Holick MF, 2008 (PubMed)",
                    "https://pubmed.ncbi.nlm.nih.gov/18290718/"
                ),
                Source(
                    "Calculated UV exposure for vitamin D synthesis",
                    "Webb & Engelsen, 2010 (PubMed)",
                    "https://pubmed.ncbi.nlm.nih.gov/20398766/"
                )
            ]
        )
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Tanora fornisce stime informative basate su fonti di salute pubblica e letteratura scientifica. Non è un dispositivo medico e non sostituisce il parere di un medico o di un dermatologo.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ForEach(topics) { topic in
                    Section {
                        ForEach(topic.sources) { source in
                            Link(destination: source.url) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(source.title)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    HStack(spacing: 6) {
                                        Text(source.publisher)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text(topic.header)
                    } footer: {
                        Text(topic.footer)
                    }
                }
            }
            .navigationTitle("Fonti scientifiche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }
}

/// Pulsante riutilizzabile che apre le fonti scientifiche. Va messo accanto ai
/// disclaimer ("stime informative, non consigli medici") così le citazioni
/// restano facili da trovare ovunque Tanora mostri stime di salute.
struct ScientificSourcesLink: View {
    var label: LocalizedStringKey = "Fonti scientifiche"
    @State private var showSources = false

    var body: some View {
        Button {
            showSources = true
        } label: {
            Label(label, systemImage: "books.vertical")
                .font(.caption.weight(.semibold))
        }
        .buttonStyle(.plain)
        .tint(.orange)
        .foregroundStyle(.orange)
        .sheet(isPresented: $showSources) {
            ScientificSourcesView()
        }
    }
}
