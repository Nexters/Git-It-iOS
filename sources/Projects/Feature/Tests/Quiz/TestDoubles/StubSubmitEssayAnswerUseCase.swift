import DomainQuizDetail

actor StubSubmitEssayAnswerUseCase {

    // MARK: Lifecycle

    init(results: [Result<EssayGrading, QuizDetailError>] = [.failure(.unexpected)]) {
        self.results = results
    }

    // MARK: Internal

    private(set) var invocations = [EssayAnswer]()

    nonisolated var gradeEssayAnswer: @Sendable (EssayAnswer) async throws -> EssayGrading {
        { try await self(answer: $0) }
    }

    func callAsFunction(answer: EssayAnswer) async throws -> EssayGrading {
        invocations.append(answer)
        return try nextResult().get()
    }

    // MARK: Private

    private var results: [Result<EssayGrading, QuizDetailError>]

    private func nextResult() -> Result<EssayGrading, QuizDetailError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
