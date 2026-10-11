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
        credential: @escaping @Sendable () async -> RequestCredential,
        credentialRejected: @escaping @Sendable () async -> Void,
    ) {
        self.init(
            client: RequestClientFactory.makeClient(
                baseURL: baseURL,
                transport: transport,
                responseTimeout: responseTimeout,
            ),
            credential: credential,
            credentialRejected: credentialRejected,
        )
    }

    init(
        client: HTTPClient,
        credential: @escaping @Sendable () async -> RequestCredential,
        credentialRejected: @escaping @Sendable () async -> Void,
    ) {
        executor = LearningProjectRequestExecutor(
            client: client,
            credential: credential,
            credentialRejected: credentialRejected,
        )
    }

    // MARK: Public

    public func fetchLearningSet(
        projectID: String,
        setID: String,
    ) async throws -> LearningSetResponseDTO {
        try await executor.send(
            LearningSetEndpoint.detail(
                projectID: projectID,
                setID: setID,
            ).request,
            expecting: LearningSetResponseDTO.self,
        )
    }

    // MARK: Private

    private let executor: LearningProjectRequestExecutor

}
