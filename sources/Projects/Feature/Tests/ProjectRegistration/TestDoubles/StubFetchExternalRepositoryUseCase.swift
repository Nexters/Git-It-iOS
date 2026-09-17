import DomainExternalRepository
import DomainIdentifier

actor StubFetchExternalRepositoryUseCase: ExternalRepositoryUseCase {

    // MARK: Lifecycle

    init(
        results: [Result<ExternalRepository, ExternalRepositoryError>] = [.failure(.other)],
        suspendsRequests: Bool = false,
    ) {
        self.results = results
        self.suspendsRequests = suspendsRequests
    }

    // MARK: Internal

    func repository(at url: ExternalRepositoryURL) async throws -> ExternalRepository {
        callCount += 1
        requestedURLs.append(url)
        let result = nextResult()
        guard suspendsRequests else { return try result.get() }

        return try await withCheckedThrowingContinuation { continuation in
            continuations.append((continuation, result))
        }
    }

    func snapshot() -> (callCount: Int, pendingCount: Int) {
        (callCount, continuations.count)
    }

    func requestedURLSnapshot() -> [ExternalRepositoryURL] {
        requestedURLs
    }

    func resumeOldest() {
        guard !continuations.isEmpty else { return }
        let (continuation, result) = continuations.removeFirst()
        continuation.resume(with: result)
    }

    func resumeNewest() {
        guard !continuations.isEmpty else { return }
        let (continuation, result) = continuations.removeLast()
        continuation.resume(with: result)
    }

    // MARK: Private

    private var results: [Result<ExternalRepository, ExternalRepositoryError>]
    private let suspendsRequests: Bool
    private var callCount = 0
    private var requestedURLs = [ExternalRepositoryURL]()
    private var continuations = [(
        CheckedContinuation<ExternalRepository, any Error>,
        Result<ExternalRepository, ExternalRepositoryError>,
    )]()

    private func nextResult() -> Result<ExternalRepository, ExternalRepositoryError> {
        guard !results.isEmpty else { return .failure(.other) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
