import DomainLearningProject

actor StubCreateLearningProjectUseCase: CreateLearningProjectUseCase {

    // MARK: Lifecycle

    init(
        results: [Result<ProjectRegistrationReceipt, LearningProjectError>] = [.failure(.unexpected)],
        suspendsRequests: Bool = false,
    ) {
        self.results = results
        self.suspendsRequests = suspendsRequests
    }

    // MARK: Internal

    struct Call: Equatable, Sendable {
        let githubRepoURL: String
        let quizLevel: QuizLevel
    }

    func callAsFunction(
        githubRepoURL: String,
        quizLevel: QuizLevel,
    ) async throws -> ProjectRegistrationReceipt {
        calls.append(Call(githubRepoURL: githubRepoURL, quizLevel: quizLevel))
        let result = nextResult()
        guard suspendsRequests else { return try result.get() }

        return try await withCheckedThrowingContinuation { continuation in
            continuations.append((continuation, result))
        }
    }

    func recordedCalls() -> [Call] {
        calls
    }

    func resumeOldest() {
        guard !continuations.isEmpty else { return }
        let (continuation, result) = continuations.removeFirst()
        continuation.resume(with: result)
    }

    // MARK: Private

    private var results: [Result<ProjectRegistrationReceipt, LearningProjectError>]
    private let suspendsRequests: Bool
    private var calls = [Call]()
    private var continuations = [(CheckedContinuation<ProjectRegistrationReceipt, any Error>, Result<ProjectRegistrationReceipt, LearningProjectError>)]()

    private func nextResult() -> Result<ProjectRegistrationReceipt, LearningProjectError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
