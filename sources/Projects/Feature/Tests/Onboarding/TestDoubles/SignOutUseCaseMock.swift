import DomainAuthentication
import DomainMember
import Foundation

actor SignOutUseCaseMock: SignOutUseCase {

    // MARK: Lifecycle

    init(results: [SignOutResult] = [.success]) {
        self.results = results
    }

    // MARK: Internal

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
        guard !results.isEmpty else { return .success }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
