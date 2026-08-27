public protocol SubmitEssayAnswerUseCase: Sendable {
    func callAsFunction(
        projectID: String,
        questionID: String,
        text: String,
    ) async throws -> EssayAnswerResult
}
