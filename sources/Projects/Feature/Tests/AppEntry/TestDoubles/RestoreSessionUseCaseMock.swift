import DomainAuthentication
import DomainMember
import Foundation

actor RestoreSessionUseCaseMock: RestoreSessionUseCase {

    // MARK: Lifecycle

    init(results: [RestoreSessionResult] = [.unauthenticated]) {
        self.results = results
    }

    // MARK: Internal

    func callAsFunction() async -> RestoreSessionResult {
        callCount += 1
        return nextResult()
    }

    func snapshot() -> Int {
        callCount
    }

    // MARK: Private

    private var results: [RestoreSessionResult]
    private var callCount = 0

    private func nextResult() -> RestoreSessionResult {
        guard !results.isEmpty else { return .recoverableFailure }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
