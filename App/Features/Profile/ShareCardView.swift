import SwiftUI
import UIKit
import OSLog

struct ShareCardMetric: Identifiable {
    let id = UUID()
    let icon: String
    let value: String
    let label: String
}

struct ShareCardContent {
    let eyebrow: String
    let headline: String
    let unit: String
    let message: String
    let metrics: [ShareCardMetric]
    let symbol: String
}

struct SharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
    let caption: String
    let source: String

    var activityItems: [Any] {
        var items: [Any] = [image, caption]
        if let appStoreURL = AppStoreLinks.appStoreURL {
            items.append(appStoreURL)
        }
        return items
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let payload: SharePayload

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: payload.activityItems,
            applicationActivities: nil
        )
        controller.completionWithItemsHandler = { activityType, completed, _, error in
            let logger = Logger(
                subsystem: Bundle.main.bundleIdentifier ?? "com.davidecapurro.Solea",
                category: "sharing"
            )
            if let error {
                logger.error("Share failed from \(payload.source, privacy: .public): \(error.localizedDescription, privacy: .public)")
            } else {
                logger.info("Share \(completed ? "completed" : "cancelled", privacy: .public) from \(payload.source, privacy: .public) via \(activityType?.rawValue ?? "unknown", privacy: .public)")
            }
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// Story card verticale: 360×640 pt, renderizzata a 3× in un PNG 1080×1920.
struct ShareCardView: View {
    let content: ShareCardContent

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.96, blue: 0.86),
                    Color(red: 1.00, green: 0.73, blue: 0.29),
                    Color(red: 0.94, green: 0.36, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: 300, height: 300)
                .offset(x: 150, y: -260)

            Circle()
                .fill(.yellow.opacity(0.20))
                .frame(width: 250, height: 250)
                .offset(x: -170, y: 270)

            VStack(alignment: .leading, spacing: 0) {
                brand
                Spacer(minLength: 26)

                Text(content.eyebrow.uppercased())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.82), in: Capsule())
                    .foregroundStyle(.white)

                Spacer(minLength: 22)

                Image(systemName: content.symbol)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.78))
                    .padding(.bottom, 8)

                Text(content.headline)
                    .font(.system(size: 78, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.54)
                    .lineLimit(1)
                    .foregroundStyle(.black.opacity(0.88))
                    .monospacedDigit()

                Text(content.unit)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.72))

                Text(content.message)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.72))
                    .lineSpacing(3)
                    .padding(.top, 18)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 26)

                metrics

                Spacer(minLength: 28)

                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "sparkles")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fai il tuo Tan Check")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Text("Stime informative basate su UV e fototipo")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .opacity(0.72)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .foregroundStyle(.white)
                .padding(16)
                .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(28)
        }
        .frame(width: 360, height: 640)
        .clipped()
        .environment(\.colorScheme, .light)
    }

    private var brand: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(.black.opacity(0.84))
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 38, height: 38)

            Text("ABBRONZO")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .tracking(1.6)
            Spacer()
            Text("TAN SMARTER")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.8)
                .opacity(0.62)
        }
        .foregroundStyle(.black.opacity(0.86))
    }

    private var metrics: some View {
        HStack(spacing: 8) {
            ForEach(content.metrics.prefix(3)) { metric in
                VStack(alignment: .leading, spacing: 5) {
                    Image(systemName: metric.icon)
                        .font(.system(size: 15, weight: .bold))
                    Text(metric.value)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text(metric.label.uppercased())
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .tracking(0.7)
                        .opacity(0.64)
                        .lineLimit(1)
                }
                .foregroundStyle(.black.opacity(0.82))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.52), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

@MainActor
func renderSharePayload<Content: View>(
    content: Content,
    caption: String,
    source: String
) -> SharePayload? {
    let renderer = ImageRenderer(content: content)
    renderer.scale = 3
    renderer.proposedSize = ProposedViewSize(width: 360, height: 640)
    renderer.isOpaque = true
    guard let image = renderer.uiImage, let cgImage = image.cgImage else { return nil }
    Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.davidecapurro.Solea",
        category: "sharing"
    ).info("Rendered \(source, privacy: .public) card at \(cgImage.width)x\(cgImage.height) px")
    #if DEBUG
    if let pngData = image.pngData() {
        let previewURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("solea-share-\(source).png")
        try? pngData.write(to: previewURL, options: .atomic)
    }
    #endif
    return SharePayload(image: image, caption: caption, source: source)
}
