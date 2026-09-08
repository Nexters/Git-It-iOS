import DomainLearningProject

actor HomeLearningProjectsUseCaseMock: FetchLearningProjectsUseCase {

    // MARK: Lifecycle

    init(
        results: [Result<LearningProjectPage, LearningProjectError>] = [.failure(.unexpected)],
        suspendsRequests: Bool = false,
    ) {
        self.results = results
        self.suspendsRequests = suspendsRequests
    }

    // MARK: Internal

    func callAsFunction(page: Int) async throws -> LearningProjectPage {
        callCount += 1
        requestedPages.append(page)
        let result = nextResult()
        guard suspendsRequests else { return try result.get() }

        return try await withCheckedThrowingContinuation { continuation in
            continuations.append((continuation, result))
        }
    }

    func snapshot() -> (callCount: Int, pendingCount: Int) {
        (callCount, continuations.count)
    }

    func requestedPageSnapshot() -> [Int] {
        requestedPages
    }

    func resumeNext() {
        guard !continuations.isEmpty else { return }
        let (continuation, result) = continuations.removeFirst()
        continuation.resume(with: result)
    }

    // MARK: Private

    private var results: [Result<LearningProjectPage, LearningProjectError>]
    private let suspendsRequests: Bool
    private var callCount = 0
    private var requestedPages = [Int]()
    private var continuations = [(
        CheckedContinuation<LearningProjectPage, any Error>,
        Result<LearningProjectPage, LearningProjectError>,
    )]()

    private func nextResult() -> Result<LearningProjectPage, LearningProjectError> {
        guard !results.isEmpty else { return .failure(.unexpected) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
