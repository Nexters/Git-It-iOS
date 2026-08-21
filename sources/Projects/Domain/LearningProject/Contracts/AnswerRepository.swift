public protocol AnswerRepository: Sendable {
    func submitChoiceAnswer(
        projectID: String,
        questionID: String,
        selectedIndex: Int,
    ) async throws -> ChoiceAnswerResult

    func submitEssayAnswer(
        projectID: String,
        questionID: String,
        text: String,
    ) async throws -> EssayAnswerResult
}
