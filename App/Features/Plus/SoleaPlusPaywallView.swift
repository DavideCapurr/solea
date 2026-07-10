import StoreKit
import SwiftUI

struct SoleaPlusPaywallView: View {
    @Environment(SoleaPlusStore.self) private var plusStore
    @Environment(\.dismiss) private var dismiss

    let source: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    featureList
                    productList
                    restoreSection
                    complianceNote
                    legalLinks
                    Color.clear.frame(height: 48)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.orange.opacity(0.16), .yellow.opacity(0.08), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Solea Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
            .task {
                await plusStore.start()
            }
            .onChange(of: plusStore.hasPlus) { _, hasPlus in
                if hasPlus {
                    dismiss()
                }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("SOLEA PLUS", systemImage: "sparkles")
                    .font(.caption.bold())
                    .tracking(1.1)
                Spacer()
                Image(systemName: "sun.max.fill")
                    .font(.title2)
                    .foregroundStyle(.black.opacity(0.62))
            }

            Text("La tua estate,\npianificata.")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .minimumScaleFactor(0.72)
                .foregroundStyle(.black.opacity(0.84))

            Text("Solea resta prudente gratis. Plus aggiunge planner, coach, trend, foto-diario e companion avanzati quando vuoi preparare davvero una stagione.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.black.opacity(0.68))

            HStack(spacing: 8) {
                heroChip("€19,99/anno", icon: "calendar")
                heroChip("Summer pass", icon: "sun.horizon.fill")
                heroChip("Disdici quando vuoi", icon: "checkmark.seal.fill")
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [.yellow.opacity(0.78), .orange.opacity(0.42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.orange.opacity(0.18), lineWidth: 1)
        }
    }

    private func heroChip(_ title: LocalizedStringKey, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption2.bold())
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 12))
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cosa sblocchi")
                .font(.headline)
            plusRow("Planner vacanze completo", icon: "airplane.departure")
            plusRow("Coach AI cloud", icon: "bubble.left.and.bubble.right.fill")
            plusRow("Foto-diario prima/dopo", icon: "camera.filters")
            plusRow("Statistiche storiche e trend", icon: "chart.xyaxis.line")
            plusRow("Reminder personalizzati e companion avanzati", icon: "bell.badge.fill")
            plusRow("Share card premium", icon: "square.and.arrow.up")
        }
    }

    private func plusRow(_ title: LocalizedStringKey, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.orange)
                .frame(width: 28)
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var productList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scegli il pass")
                .font(.headline)

            ForEach(SoleaPlusProductID.merchandised, id: \.rawValue) { id in
                productButton(id)
            }

            if plusStore.isLoadingProducts {
                HStack {
                    ProgressView()
                    Text("Carico i prezzi App Store…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let notice = plusStore.noticeMessage {
                Label(notice, systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func productButton(_ id: SoleaPlusProductID) -> some View {
        #if DEBUG
        let usesScreenshotFallback = ProcessInfo.processInfo.arguments.contains("-soleaScreenshotDemo")
        #else
        let usesScreenshotFallback = false
        #endif
        let product = plusStore.product(for: id)
        let title = usesScreenshotFallback ? id.fallbackTitle : (product?.displayName ?? id.fallbackTitle)
        let price = usesScreenshotFallback ? id.fallbackPriceText : (product?.displayPrice ?? id.fallbackPriceText)
        let isAnnual = id == .annual
        #if DEBUG
        let canSelect = product != nil || usesScreenshotFallback
        #else
        let canSelect = product != nil
        #endif
        let subtitle: LocalizedStringKey = id == .annual
            ? "Miglior valore se usi Solea tutto l'anno."
            : "Accesso Plus per la stagione estiva."

        return Button {
            guard let product else { return }
            Task { await plusStore.purchase(product) }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isAnnual ? "sparkles" : "sun.max.fill")
                    .font(.title3.bold())
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(isAnnual ? 0.50 : 0.80), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.headline)
                        if isAnnual {
                            Text("PIÙ SCELTO")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .tracking(0.8)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.black.opacity(0.82), in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(isAnnual ? .black.opacity(0.62) : .secondary)
                }
                Spacer()
                Text(price)
                    .font(.headline.monospacedDigit())
            }
            .foregroundStyle(isAnnual ? .black.opacity(0.84) : .primary)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(productBackground(isAnnual: isAnnual))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isAnnual ? .orange.opacity(0.20) : .orange.opacity(0.30), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!canSelect || plusStore.isPurchasing)
    }

    @ViewBuilder
    private func productBackground(isAnnual: Bool) -> some View {
        if isAnnual {
            LinearGradient(
                colors: [.yellow.opacity(0.78), .orange.opacity(0.42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        } else {
            RoundedRectangle(cornerRadius: 18)
                .fill(.regularMaterial)
        }
    }

    private var restoreSection: some View {
        Button {
            Task { await plusStore.restorePurchases() }
        } label: {
            Label("Ripristina acquisti", systemImage: "arrow.clockwise")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.orange)
        .disabled(plusStore.isPurchasing)
    }

    private var complianceNote: some View {
        Text("Solea Plus annuale (€19,99/anno) è un abbonamento auto-rinnovabile: si rinnova automaticamente allo stesso prezzo salvo disdetta almeno 24 ore prima della fine del periodo, e si gestisce o annulla dalle impostazioni dell'account Apple. Il Summer Pass (€9,99) è un acquisto una tantum valido 120 giorni, non si rinnova. Gli acquisti e il ripristino passano sempre dall'In-App Purchase dell'App Store. Solea Plus non sostituisce il parere medico.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
    }

    private var legalLinks: some View {
        // Linee guida App Store 3.1.2: il flusso di acquisto deve contenere
        // link funzionanti a Termini d'uso (EULA) e informativa privacy.
        VStack(alignment: .leading, spacing: 8) {
            Link(destination: AppStoreLinks.termsOfUseURL) {
                Label("Termini d'uso (EULA)", systemImage: "doc.text")
            }
            if let privacyPolicyURL = AppStoreLinks.privacyPolicyURL {
                Link(destination: privacyPolicyURL) {
                    Label("Informativa privacy", systemImage: "hand.raised")
                }
            }
        }
        .font(.caption.weight(.medium))
        .tint(.orange)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}

struct SoleaPlusLockedView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let systemImage: String
    let source: String

    @State private var showPaywall = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(spacing: dynamicTypeSize.isAccessibilitySize ? 12 : 18) {
                VStack(spacing: dynamicTypeSize.isAccessibilitySize ? 10 : 14) {
                    Label("SOLEA PLUS", systemImage: "sparkles")
                        .font(.caption.bold())
                        .tracking(1.1)
                        .foregroundStyle(.black.opacity(0.62))

                    Image(systemName: systemImage)
                        .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 34 : 52, weight: .bold))
                        .foregroundStyle(.black.opacity(0.78))

                    Text(title)
                        .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 23 : 34, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.black.opacity(0.84))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message)
                        .font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.black.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(dynamicTypeSize.isAccessibilitySize ? 20 : 26)
                .frame(maxWidth: .infinity)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .background(
                    LinearGradient(
                        colors: [.yellow.opacity(0.72), .orange.opacity(0.42)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 24)
                )

                Text("UV live, limite prudente, quiz, timer base e diario base restano sempre gratuiti.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

                Button {
                    showPaywall = true
                } label: {
                    Label("Scopri Solea Plus", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)
                Color.clear.frame(height: dynamicTypeSize.isAccessibilitySize ? 104 : 72)
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.12), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showPaywall) {
            SoleaPlusPaywallView(source: source)
        }
    }
}
