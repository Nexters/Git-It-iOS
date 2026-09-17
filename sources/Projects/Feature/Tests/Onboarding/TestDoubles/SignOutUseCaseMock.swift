import DomainAccount
import Foundation

actor SignOutUseCaseMock {

    // MARK: Lifecycle

    init(results: [SignOutResult] = [.signedOut]) {
        self.results = results
    }

    // MARK: Internal

    nonisolated var signOut: @Sendable () async -> SignOutResult {
        { await self() }
    }

    func callAsFunction() async -> SignOutResult {
        callCount += 1
        return nextResult()
    }

    func snapshot() -> Int {
        callCount
    }

    // MARK: Private

    private var results: [SignOutResult]
    private var callCount = 0

    private func nextResult() -> SignOutResult {
        guard !results.isEmpty else { return .signedOut }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
