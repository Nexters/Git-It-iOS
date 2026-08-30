import Foundation
import InfrastructureNetworkClient

// MARK: - HTTPAnswerRemote

public struct HTTPAnswerRemote: AnswerRemote {

    // MARK: Lifecycle

    public init(
        client: HTTPClient,
        accessTokenProvider: @escaping @Sendable () async -> String?,
    ) {
        executor = LearningProjectHTTPExecutor(client: client, accessTokenProvider: accessTokenProvider)
    }

    // MARK: Public

    public func submitChoiceAnswer(
        projectID: String,
        questionID: String,
        request: SubmitChoiceAnswerRequestDTO,
    ) async throws -> SubmitChoiceAnswerResponseDTO {
        try await executor.send(
            AnswerEndpoint.choice(projectID: projectID, questionID: questionID).request,
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
            AnswerEndpoint.essay(projectID: projectID, questionID: questionID).request,
            body: request,
            expecting: SubmitEssayAnswerResponseDTO.self,
        )
    }

    // MARK: Private

    private let executor: LearningProjectHTTPExecutor

}
