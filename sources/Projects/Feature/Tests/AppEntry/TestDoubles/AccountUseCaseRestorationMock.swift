import DomainUseCaseInterface
import Foundation

actor AccountUseCaseRestorationMock {

    // MARK: Lifecycle

    init(
        results: [SignInRestoration] = [.signedOut],
        suspendsRequests: Bool = false,
    ) {
        self.results = results
        self.suspendsRequests = suspendsRequests
    }

    // MARK: Internal

    nonisolated var restoreSignIn: @Sendable () async -> SignInRestoration {
        { await self() }
    }

    func callAsFunction() async -> SignInRestoration {
        callCount += 1
        let result = nextResult()
        guard suspendsRequests else { return result }

        return await withCheckedContinuation { continuation in
            continuations.append((continuation, result))
        }
    }

    func snapshot() -> Int {
        callCount
    }

    func resumeOldest() {
        guard !continuations.isEmpty else { return }
        let (continuation, result) = continuations.removeFirst()
        continuation.resume(returning: result)
    }

    // MARK: Private

    private var results: [SignInRestoration]
    private let suspendsRequests: Bool
    private var callCount = 0
    private var continuations = [(CheckedContinuation<SignInRestoration, Never>, SignInRestoration)]()

    private func nextResult() -> SignInRestoration {
        guard !results.isEmpty else { return .temporarilyUnavailable }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
