import Foundation

public struct FetchExternalRepository: Sendable {

    // MARK: Lifecycle

    public init(lookup: ExternalRepositoryLookup) {
        self.lookup = lookup
    }

    // MARK: Public

    public func callAsFunction(url: String) async throws -> ExternalRepository {
        guard let (owner, name) = Self.parseOwnerAndRepositoryName(from: url)
        else {
            throw ExternalRepositoryError.invalidURLFormat
        }

        return try await lookup.repository(owner: owner, name: name)
    }

    // MARK: Private

    private let lookup: ExternalRepositoryLookup

    private static func parseOwnerAndRepositoryName(from url: String) -> (owner: String, name: String)? {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            !trimmed.isEmpty,
            let components = URLComponents(string: trimmed),
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

        return (owner, name)
    }

}
