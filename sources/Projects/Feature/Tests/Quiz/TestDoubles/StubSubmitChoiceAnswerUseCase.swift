import DomainLearningProject

actor StubSubmitChoiceAnswerUseCase: SubmitChoiceAnswerUseCase {

    // MARK: Lifecycle

    init(results: [Result<ChoiceAnswerResult, LearningProjectError>] = [.failure(.unexpected)]) {
        self.results = results
    }

    // MARK: Internal

    struct Invocation: Equatable, Sendable {
        let projectID: String
        let questionID: String
        let selectedIndex: Int
    }

    private(set) var invocations = [Invocation]()

    func callAsFunction(
        projectID: String,
        questionID: String,
        selectedIndex: Int,
    ) async throws -> ChoiceAnswerResult {
        invocations.append(
            Invocation(projectID: projectID, questionID: questionID, selectedIndex: selectedIndex)
        )
        return try nextResult().get()
    }

    // MARK: Private

    private var results: [Result<ChoiceAnswerResult, LearningProjectError>]

    private func nextResult() -> Result<ChoiceAnswerResult, LearningProjectError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
