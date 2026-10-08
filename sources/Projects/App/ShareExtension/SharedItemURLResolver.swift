import Foundation

// MARK: - SharedItemURLResolver

struct SharedItemURLResolver: Sendable {

    // MARK: Lifecycle

    init() { }

    // MARK: Internal

    static func url(fromText text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let url = URL(string: trimmed),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            url.host != nil
        else { return nil }
        return url
    }

    func resolve(from providers: [any SharedItemAttachment]) async -> URL? {
        for provider in providers {
            if let url = await provider.loadURL() {
                return url
            }
        }
        for provider in providers {
            if
                let text = await provider.loadText(),
                let url = Self.url(fromText: text)
            {
                return url
            }
        }
        return nil
    }

}
