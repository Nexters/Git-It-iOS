import DomainAccount
import Foundation

actor AccountUseCaseSignInMock {

    // MARK: Lifecycle

    init(
        results: [SignInResult] = [.retryableFailure],
        suspendsRequests: Bool = false,
    ) {
        self.results = results
        self.suspendsRequests = suspendsRequests
    }

    // MARK: Internal

    nonisolated var signIn: @Sendable (SignInMethod) async -> SignInResult {
        { await self($0) }
    }

    func callAsFunction(_ method: SignInMethod) async -> SignInResult {
        calls.append(method)
        let result = nextResult()
        guard suspendsRequests else { return result }

        return await withCheckedContinuation { continuation in
            continuations.append((continuation, result))
        }
    }

    func snapshot() -> [SignInMethod] {
        calls
    }

    func resumeOldest() {
        guard !continuations.isEmpty else { return }
        let (continuation, result) = continuations.removeFirst()
        continuation.resume(returning: result)
    }

    // MARK: Private

    private var results: [SignInResult]
    private let suspendsRequests: Bool
    private var calls = [SignInMethod]()
    private var continuations = [(CheckedContinuation<SignInResult, Never>, SignInResult)]()

    private func nextResult() -> SignInResult {
        guard !results.isEmpty else { return .retryableFailure }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
