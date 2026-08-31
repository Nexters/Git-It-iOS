import DomainMember

actor HomeMemberProfileUseCaseMock: FetchMemberProfileUseCase {

    // MARK: Lifecycle

    init(
        results: [Result<MemberProfile, MemberError>] = [.failure(.temporarilyUnavailable)],
        suspendsRequests: Bool = false,
    ) {
        self.results = results
        self.suspendsRequests = suspendsRequests
    }

    // MARK: Internal

    func callAsFunction() async throws -> MemberProfile {
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

    private var results: [Result<MemberProfile, MemberError>]
    private let suspendsRequests: Bool
    private var callCount = 0
    private var continuations = [(CheckedContinuation<MemberProfile, any Error>, Result<MemberProfile, MemberError>)]()

    private func nextResult() -> Result<MemberProfile, MemberError> {
        guard !results.isEmpty else { return .failure(.temporarilyUnavailable) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
