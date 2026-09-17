import DomainAccount
import Foundation

actor AccountUseCaseRestorationMock {

    // MARK: Lifecycle

    init(results: [SignInRestoration] = [.signedOut]) {
        self.results = results
    }

    // MARK: Internal

    nonisolated var restoreSignIn: @Sendable () async -> SignInRestoration {
        { await self() }
    }

    func callAsFunction() async -> SignInRestoration {
        callCount += 1
        return nextResult()
    }

    func snapshot() -> Int {
        callCount
    }

    // MARK: Private

    private var results: [SignInRestoration]
    private var callCount = 0

    private func nextResult() -> SignInRestoration {
        guard !results.isEmpty else { return .temporarilyUnavailable }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
