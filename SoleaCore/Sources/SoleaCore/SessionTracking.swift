import Foundation

public enum ExposureSide: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case front
    case back

    public var id: String { rawValue }
}

public enum SkinResponse: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case notLogged
    case comfortable
    case warm
    case tight
    case red

    public var id: String { rawValue }
}
