import SwiftUI

enum SoleaTheme {
    static let sunshine = Color(red: 1.00, green: 0.82, blue: 0.18)
    static let sunset = Color(red: 0.96, green: 0.42, blue: 0.14)
    static let coral = Color(red: 0.91, green: 0.23, blue: 0.20)
    static let aqua = Color(red: 0.08, green: 0.56, blue: 0.68)
    static let mint = Color(red: 0.12, green: 0.60, blue: 0.36)
    static let violet = Color(red: 0.48, green: 0.32, blue: 0.86)

    static var screenGradient: LinearGradient {
        LinearGradient(
            colors: [
                sunshine.opacity(0.18),
                sunset.opacity(0.10),
                aqua.opacity(0.08),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var sunriseGradient: LinearGradient {
        LinearGradient(
            colors: [
                sunshine.opacity(0.76),
                Color.orange.opacity(0.48),
                coral.opacity(0.26)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func softGradient(from tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                tint.opacity(0.22),
                tint.opacity(0.08),
                Color(.secondarySystemBackground).opacity(0.72)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
