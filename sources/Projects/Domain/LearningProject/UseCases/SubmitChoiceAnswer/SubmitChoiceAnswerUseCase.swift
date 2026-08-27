public protocol SubmitChoiceAnswerUseCase: Sendable {
    func callAsFunction(
        projectID: String,
        questionID: String,
        selectedIndex: Int,
    ) async throws -> ChoiceAnswerResult
}
