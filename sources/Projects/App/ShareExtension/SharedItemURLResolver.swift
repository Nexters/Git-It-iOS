import Foundation
import UniformTypeIdentifiers

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

// MARK: - SharedItemAttachment

protocol SharedItemAttachment: Sendable {

    func loadURL() async -> URL?

    func loadText() async -> String?

}

// MARK: - NSItemProvider + SharedItemAttachment

extension NSItemProvider: SharedItemAttachment {

    func loadURL() async -> URL? {
        guard hasItemConformingToTypeIdentifier(UTType.url.identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            loadItem(forTypeIdentifier: UTType.url.identifier) { item, _ in
                continuation.resume(returning: item as? URL)
            }
        }
    }

    func loadText() async -> String? {
        guard hasItemConformingToTypeIdentifier(UTType.plainText.identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            loadItem(forTypeIdentifier: UTType.plainText.identifier) { item, _ in
                continuation.resume(returning: item as? String)
            }
        }
    }

}
