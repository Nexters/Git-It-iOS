import Foundation
import UniformTypeIdentifiers

// MARK: - SharedItemURLResolver

/// 호스트 앱이 전달한 공유 항목에서 사용할 URL을 얻는다. URL 타입을 우선 확인하고,
/// 없을 때만 텍스트 타입을 URL로 변환해 본다.
struct SharedItemURLResolver: Sendable {

    // MARK: Lifecycle

    init() { }

    // MARK: Internal

    /// 여러 항목이 전달되면 URL로 해석되는 첫 항목을 사용한다.
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

}

// MARK: - SharedItemAttachment

/// 테스트에서 `NSItemProvider` 없이 수신 규칙을 검증하기 위한 경계다.
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
