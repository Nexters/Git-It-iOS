import DomainAccount
import Foundation

actor AccountUseCaseSignInMock {

    // MARK: Lifecycle

    init(results: [SignInResult] = [.retryableFailure]) {
        self.results = results
    }

    // MARK: Internal

    nonisolated var signIn: @Sendable (SignInMethod) async -> SignInResult {
        { await self($0) }
    }

    func callAsFunction(_ method: SignInMethod) async -> SignInResult {
        calls.append(method)
        return nextResult()
    }

    func snapshot() -> [SignInMethod] {
        calls
    }

    // MARK: Private

    private var results: [SignInResult]
    private var calls = [SignInMethod]()

    private func nextResult() -> SignInResult {
        guard !results.isEmpty else { return .retryableFailure }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
