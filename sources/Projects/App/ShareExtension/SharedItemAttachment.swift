import Foundation
import UniformTypeIdentifiers

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
