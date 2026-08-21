import DataExternalRepository
import DomainLearningProject

// MARK: - ExternalRepositoryLookupAdapter

struct ExternalRepositoryLookupAdapter: ExternalRepositoryLookup {

    // MARK: Lifecycle

    init(remote: ExternalRepositoryRemote) {
        self.remote = remote
    }

    // MARK: Internal

    func repository(
        owner: String,
        name: String,
    ) async throws -> ExternalRepository {
        do {
            let response = try await remote.repository(GitHubRepositoryRequest(owner: owner, repository: name))
            return ExternalRepository(
                canonicalURL: response.htmlURL,
                ownerName: owner,
                repositoryName: name,
                imageURL: response.ownerAvatarURL,
                starCount: response.starCount,
                techStack: response.topics,
            )
        } catch let error as DataExternalRepositoryError {
            throw domainError(for: error)
        }
    }

    // MARK: Private

    private let remote: ExternalRepositoryRemote

    private func domainError(for error: DataExternalRepositoryError) -> ExternalRepositoryError {
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
