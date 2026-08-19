import DataLearningProject
import DomainLearningProject

public struct ExternalRepositoryLookupAdapter: ExternalRepositoryLookup {

    // MARK: Lifecycle

    public init(remote: ExternalRepositoryRemote) {
        self.remote = remote
    }

    // MARK: Public

    public func repository(
        owner: String,
        name: String,
    ) async throws -> ExternalRepository {
        do {
            let dto = try await remote.repository(owner: owner, name: name)
            return ExternalRepository(
                canonicalURL: dto.htmlURL,
                ownerName: owner,
                repositoryName: name,
                imageURL: dto.ownerAvatarURL,
                starCount: dto.starCount,
                techStack: dto.topics,
            )
        } catch DataExternalRepositoryError.offline {
            throw ExternalRepositoryError.offline
        } catch {
            throw ExternalRepositoryError.other
        }
    }

    // MARK: Private

    private let remote: ExternalRepositoryRemote

}
