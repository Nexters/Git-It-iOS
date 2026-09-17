import DomainUserInfo

actor HomeMemberProfileUseCaseMock {

    // MARK: Lifecycle

    init(
        results: [Result<UserProfile, UserInfoError>] = [.failure(.temporarilyUnavailable)],
        suspendsRequests: Bool = false,
    ) {
        self.results = results
        self.suspendsRequests = suspendsRequests
    }

    // MARK: Internal

    nonisolated var fetchProfile: @Sendable () async throws -> UserProfile {
        { try await self() }
    }

    func callAsFunction() async throws -> UserProfile {
        callCount += 1
        let result = nextResult()
        guard suspendsRequests else { return try result.get() }

        return try await withCheckedThrowingContinuation { continuation in
            continuations.append((continuation, result))
        }
    }

    func snapshot() -> (callCount: Int, pendingCount: Int) {
        (callCount, continuations.count)
    }

    func resumeNext() {
        guard !continuations.isEmpty else { return }
        let (continuation, result) = continuations.removeFirst()
        continuation.resume(with: result)
    }

    // MARK: Private

    private var results: [Result<UserProfile, UserInfoError>]
    private let suspendsRequests: Bool
    private var callCount = 0
    private var continuations = [(
        CheckedContinuation<UserProfile, any Error>,
        Result<UserProfile, UserInfoError>,
    )]()

    private func nextResult() -> Result<UserProfile, UserInfoError> {
        guard !results.isEmpty else { return .failure(.temporarilyUnavailable) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
