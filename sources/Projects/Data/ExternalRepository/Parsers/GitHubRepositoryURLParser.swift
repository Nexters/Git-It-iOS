import Foundation

// MARK: - GitHubRepositoryURLParser

/// GitHub 저장소 URL 문자열을 소유자와 저장소 이름으로 해석한다. 공유 시트로 들어온 URL과
/// 사용자가 직접 입력한 URL이 같은 규칙으로 판정되도록 이 타입 하나가 규칙을 소유한다.
public struct GitHubRepositoryURLParser: Sendable {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func location(from url: String) -> ExternalRepositoryLocation? {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            !trimmed.isEmpty,
            let components = URLComponents(string: Self.normalizedURLString(from: trimmed)),
            let host = components.host?.lowercased(),
            host == "github.com" || host == "www.github.com"
        else {
            return nil
        }

        let segments = components.path
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)

        guard
            segments.count >= 2,
            !segments[0].isEmpty
        else {
            return nil
        }

        let owner = segments[0]
        let name = segments[1].hasSuffix(".git") ? String(segments[1].dropLast(4)) : segments[1]

        guard !name.isEmpty
        else {
            return nil
        }

        return ExternalRepositoryLocation(owner: owner, name: name)
    }

    // MARK: Private

    /// scheme이 없는 입력(`github.com/owner/repo`, `www.github.com/owner/repo`)에
    /// `https://`를 보충해 `http://`, `https://`, `www.` 조합 모두 host 판별이
    /// 가능하도록 한다.
    private static func normalizedURLString(from trimmed: String) -> String {
        let lowercased = trimmed.lowercased()
        guard lowercased.hasPrefix("http://") || lowercased.hasPrefix("https://")
        else {
            return "https://\(trimmed)"
        }
        return trimmed
    }

}
