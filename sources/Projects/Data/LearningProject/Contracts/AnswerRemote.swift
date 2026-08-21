public protocol AnswerRemote: Sendable {
    func submitChoiceAnswer(
        projectID: String,
        questionID: String,
        request: SubmitChoiceAnswerRequestDTO,
    ) async throws -> SubmitChoiceAnswerResponseDTO
    func submitEssayAnswer(
        projectID: String,
        questionID: String,
        request: SubmitEssayAnswerRequestDTO,
    ) async throws -> SubmitEssayAnswerResponseDTO
}
