public struct FetchExternalRepository: FetchExternalRepositoryUseCase {

    // MARK: Lifecycle

    public init(
        lookup: any ExternalRepositoryLookup,
        urlParser: any ExternalRepositoryURLParser,
    ) {
        self.lookup = lookup
        self.urlParser = urlParser
    }

    // MARK: Public

    public func callAsFunction(url: String) async throws -> ExternalRepository {
        guard let location = urlParser.location(from: url)
        else {
            throw ExternalRepositoryError.invalidURLFormat
        }

        return try await lookup.repository(owner: location.owner, name: location.name)
    }

    // MARK: Private

    private let lookup: any ExternalRepositoryLookup
    private let urlParser: any ExternalRepositoryURLParser

}
