public struct FetchExternalRepository: FetchExternalRepositoryUseCase {

    // MARK: Lifecycle

    public init(
        lookup: any ExternalRepositoryLookup,
        locator: any ExternalRepositoryLocator,
    ) {
        self.lookup = lookup
        self.locator = locator
    }

    // MARK: Public

    public func callAsFunction(url: String) async throws -> ExternalRepository {
        guard let location = locator.location(from: url)
        else {
            throw ExternalRepositoryError.invalidURLFormat
        }

        return try await lookup.repository(owner: location.owner, name: location.name)
    }

    // MARK: Private

    private let lookup: any ExternalRepositoryLookup
    private let locator: any ExternalRepositoryLocator

}
