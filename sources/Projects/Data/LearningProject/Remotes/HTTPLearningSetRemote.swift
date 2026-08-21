import Foundation
import InfrastructureNetworkClient

// MARK: - HTTPLearningSetRemote

public struct HTTPLearningSetRemote: LearningSetRemote {

    // MARK: Lifecycle

    public init(
        client: HTTPClient,
        accessTokenProvider: @escaping @Sendable () async -> String?,
    ) {
        executor = LearningProjectHTTPExecutor(client: client, accessTokenProvider: accessTokenProvider)
    }

    // MARK: Public

    public func fetchLearningSet(
        projectID: String,
        setID: String,
    ) async throws -> LearningSetResponseDTO {
        try await executor.send(
            LearningSetEndpoint.detail(projectID: projectID, setID: setID).request,
            expecting: LearningSetResponseDTO.self,
        )
    }

    // MARK: Private

    private let executor: LearningProjectHTTPExecutor

}
