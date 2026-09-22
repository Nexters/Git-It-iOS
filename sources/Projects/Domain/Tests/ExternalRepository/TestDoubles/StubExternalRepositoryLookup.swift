@testable import DomainExternalRepository

actor StubExternalRepositoryLookup: ExternalRepositoryLookup {

    // MARK: Lifecycle

    init(repository: ExternalRepository) {
        self.repository = repository
    }

    // MARK: Internal

    private(set) var requestedLocations = [ExternalRepositoryLocation]()

    func repository(
        owner: String,
        name: String,
    ) async throws -> ExternalRepository {
        requestedLocations.append(ExternalRepositoryLocation(
            owner: owner,
            name: name,
        ))
        return repository
    }

    // MARK: Private

    private let repository: ExternalRepository

}
