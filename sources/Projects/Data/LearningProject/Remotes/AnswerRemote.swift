import DataShared
import Foundation
import InfrastructureNetworkClient

// MARK: - AnswerRemote

public struct AnswerRemote: Sendable {

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

    public func submitChoiceAnswer(
        projectID: String,
        questionID: String,
        request: SubmitChoiceAnswerRequestDTO,
    ) async throws -> SubmitChoiceAnswerResponseDTO {
        try await executor.send(
            AnswerEndpoint.choice(
                projectID: projectID,
                questionID: questionID,
            ).request,
            body: request,
            expecting: SubmitChoiceAnswerResponseDTO.self,
        )
    }

    public func submitEssayAnswer(
        projectID: String,
        questionID: String,
        request: SubmitEssayAnswerRequestDTO,
    ) async throws -> SubmitEssayAnswerResponseDTO {
        try await executor.send(
            AnswerEndpoint.essay(
                projectID: projectID,
                questionID: questionID,
            ).request,
            body: request,
            expecting: SubmitEssayAnswerResponseDTO.self,
        )
    }

    // MARK: Private

    private let executor: LearningProjectRequestExecutor

}
