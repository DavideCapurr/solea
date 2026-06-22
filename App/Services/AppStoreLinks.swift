import Foundation

enum AppStoreLinks {
    static var appStoreURL: URL? {
        bundleURL(for: "SoleaAppStoreURL")
    }

    static var privacyPolicyURL: URL? {
        bundleURL(for: "SoleaPrivacyPolicyURL")
    }

    static var supportURL: URL? {
        bundleURL(for: "SoleaSupportURL")
    }

    private static func bundleURL(for key: String) -> URL? {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isPlaceholder(trimmed), let url = URL(string: trimmed) else {
            return nil
        }
        guard url.scheme == "https" || url.scheme == "http" else {
            return nil
        }
        return url
    }

    private static func isPlaceholder(_ value: String) -> Bool {
        let lowered = value.lowercased()
        return lowered.contains("example.com")
            || lowered.contains("todo")
            || lowered.contains("tbd")
            || lowered.contains("placeholder")
    }
}
