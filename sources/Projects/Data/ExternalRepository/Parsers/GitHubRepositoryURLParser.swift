import Foundation

// MARK: - GitHubRepositoryURLParser

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

    private static func normalizedURLString(from trimmed: String) -> String {
        let lowercased = trimmed.lowercased()
        guard lowercased.hasPrefix("http://") || lowercased.hasPrefix("https://")
        else {
            return "https://\(trimmed)"
        }
        return trimmed
    }

}
