import DomainAuthentication
import DomainMember
import Foundation

actor SignInUseCaseMock: SignInUseCase {

    // MARK: Lifecycle

    init(results: [SignInResult] = [.retryableFailure]) {
        self.results = results
    }

    // MARK: Internal

    func callAsFunction(_ method: AuthenticationMethod) async -> SignInResult {
        calls.append(method)
        return nextResult()
    }

    func snapshot() -> [AuthenticationMethod] {
        calls
    }

    // MARK: Private

    private var results: [SignInResult]
    private var calls = [AuthenticationMethod]()

    private func nextResult() -> SignInResult {
        guard !results.isEmpty else { return .retryableFailure }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
