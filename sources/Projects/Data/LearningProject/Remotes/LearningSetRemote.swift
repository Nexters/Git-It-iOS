import DataShared
import Foundation
import InfrastructureNetworkClient

// MARK: - LearningSetRemote

public struct LearningSetRemote: Sendable {

    // MARK: Lifecycle

    public init(
        baseURL: URL,
        transport: (any RequestTransport)?,
        responseTimeout: Duration,
        accessTokenProvider: @escaping @Sendable () async -> String?,
    ) {
        self.init(
            client: RequestClientFactory.makeClient(
                baseURL: baseURL,
                transport: transport,
                responseTimeout: responseTimeout,
            ),
            accessTokenProvider: accessTokenProvider,
        )
    }

    init(
        client: HTTPClient,
        accessTokenProvider: @escaping @Sendable () async -> String?,
    ) {
        executor = LearningProjectRequestExecutor(client: client, accessTokenProvider: accessTokenProvider)
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

    private let executor: LearningProjectRequestExecutor

}
