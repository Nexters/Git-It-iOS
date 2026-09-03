import DomainLearningProject

actor StubSubmitEssayAnswerUseCase: SubmitEssayAnswerUseCase {

    // MARK: Lifecycle

    init(results: [Result<EssayAnswerResult, LearningProjectError>] = [.failure(.unexpected)]) {
        self.results = results
    }

    // MARK: Internal

    struct Invocation: Equatable, Sendable {
        let projectID: String
        let questionID: String
        let text: String
    }

    private(set) var invocations = [Invocation]()

    func callAsFunction(
        projectID: String,
        questionID: String,
        text: String,
    ) async throws -> EssayAnswerResult {
        invocations.append(Invocation(projectID: projectID, questionID: questionID, text: text))
        return try nextResult().get()
    }

    // MARK: Private

    private var results: [Result<EssayAnswerResult, LearningProjectError>]

    private func nextResult() -> Result<EssayAnswerResult, LearningProjectError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
