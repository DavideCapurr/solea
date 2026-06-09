import Foundation

/// Un campione orario della previsione UV.
public struct UVHour: Hashable, Sendable {
    public let date: Date
    public let uvIndex: Double

    public init(date: Date, uvIndex: Double) {
        self.date = date
        self.uvIndex = uvIndex
    }
}
