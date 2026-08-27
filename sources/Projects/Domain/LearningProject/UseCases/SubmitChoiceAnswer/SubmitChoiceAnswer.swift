public struct SubmitChoiceAnswer: SubmitChoiceAnswerUseCase {

    // MARK: Lifecycle

    public init(repository: AnswerRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction(
        projectID: String,
        questionID: String,
        selectedIndex: Int,
    ) async throws -> ChoiceAnswerResult {
        guard selectedIndex >= 0 else {
            throw LearningProjectError.invalidRequest
        }

        return try await repository.submitChoiceAnswer(
            projectID: projectID,
            questionID: questionID,
            selectedIndex: selectedIndex,
        )
    }

    // MARK: Private

    private let repository: AnswerRepository

}
