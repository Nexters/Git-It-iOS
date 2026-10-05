import DataExternalRepository
import DomainUseCaseDependency
import DomainUseCaseInterface

// MARK: - ExternalRepositoryLookupAdapter

public struct ExternalRepositoryLookupAdapter: DomainUseCaseDependency.ExternalRepositoryLookup {

    // MARK: Lifecycle

    public init(remote: ExternalRepositoryRemote) {
        self.remote = remote
    }

    // MARK: Public

    public func repository(
        owner: String,
        name: String,
    ) async throws -> DomainUseCaseInterface.ExternalRepository {
        do {
            let response = try await remote.repository(GitHubRepositoryRequest(
                owner: owner,
                repository: name,
            ))
            return DomainUseCaseInterface.ExternalRepository(
                canonicalURL: response.htmlURL,
                ownerName: response.ownerLogin,
                repositoryName: response.repositoryName,
                imageURL: response.ownerAvatarURL,
                starCount: response.starCount,
                techStack: response.topics,
            )
        } catch let error as ExternalRepositoryFetchError {
            throw domainError(for: error)
        }
    }

    // MARK: Private

    private let remote: ExternalRepositoryRemote

    private func domainError(for error: ExternalRepositoryFetchError) -> ExternalRepositoryError {
        switch error {
        case .offline:
            .offline

        case .other:
            .other

        @unknown default:
            .other
        }
    }

}
