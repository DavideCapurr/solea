import SwiftUI
import SoleaCore

/// Card condivisibile con streak, badge e progressi. Renderizzata in immagine
/// via `ImageRenderer` e condivisa con la share sheet di sistema.
struct ShareCardView: View {
    let phototype: Fitzpatrick
    let streak: Int
    let unlockedBadges: Set<Badge>
    let totalVitaminDIU: Double

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.orange)
                Text("Solea")
                    .font(.title2.bold())
            }

            Text("\(streak)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)
            Text("giorni di sole intelligente")
                .font(.headline)

            HStack(spacing: 20) {
                ForEach(Array(unlockedBadges).sorted(by: { $0.rawValue < $1.rawValue })) { badge in
                    Image(systemName: badge.systemImage)
                        .font(.title2)
                        .foregroundStyle(.orange)
                }
            }

            Text("Fototipo \(phototype.romanNumeral) · ≈ \(Int(totalVitaminDIU)) IU vitamina D")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(width: 320, height: 400)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color.orange.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

extension ShareCardView {
    /// Renderizza la card in immagine. `nil` se il rendering fallisce.
    @MainActor
    func renderedImage(scale: CGFloat = 3) -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = scale
        return renderer.uiImage
    }
}
