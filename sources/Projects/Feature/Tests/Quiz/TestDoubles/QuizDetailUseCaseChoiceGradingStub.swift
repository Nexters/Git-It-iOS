import DomainQuizDetail

actor QuizDetailUseCaseChoiceGradingStub {

    // MARK: Lifecycle

    init(results: [Result<ChoiceGrading, QuizDetailError>] = [.failure(.unexpected)]) {
        self.results = results
    }

    // MARK: Internal

    private(set) var invocations = [ChoiceAnswer]()

    nonisolated var gradeChoiceAnswer: @Sendable (ChoiceAnswer) async throws -> ChoiceGrading {
        { try await self(answer: $0) }
    }

    func callAsFunction(answer: ChoiceAnswer) async throws -> ChoiceGrading {
        invocations.append(answer)
        return try nextResult().get()
    }

    // MARK: Private

    private var results: [Result<ChoiceGrading, QuizDetailError>]

    private func nextResult() -> Result<ChoiceGrading, QuizDetailError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
