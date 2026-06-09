import Foundation

/// Zone del corpo esposte al sole durante una sessione.
public struct ExposedZones: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let face = ExposedZones(rawValue: 1 << 0)
    public static let torso = ExposedZones(rawValue: 1 << 1)
    public static let back = ExposedZones(rawValue: 1 << 2)
    public static let arms = ExposedZones(rawValue: 1 << 3)
    public static let legs = ExposedZones(rawValue: 1 << 4)

    public static let all: ExposedZones = [.face, .torso, .back, .arms, .legs]

    /// Frazione di superficie corporea esposta ("regola del nove" semplificata).
    public var bodyFraction: Double {
        var fraction = 0.0
        if contains(.face) { fraction += 0.05 }
        if contains(.torso) { fraction += 0.18 }
        if contains(.back) { fraction += 0.18 }
        if contains(.arms) { fraction += 0.18 }
        if contains(.legs) { fraction += 0.36 }
        return fraction
    }
}
