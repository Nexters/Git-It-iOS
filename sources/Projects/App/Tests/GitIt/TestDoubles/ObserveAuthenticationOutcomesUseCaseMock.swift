import DomainAuthentication
import DomainLearningProject
import DomainMember
import Foundation

actor ObserveAuthenticationOutcomesUseCaseMock: ObserveAuthenticationOutcomesUseCase {

    // MARK: Internal

    func callAsFunction() async -> AsyncStream<AuthenticationOutcome> {
        let (stream, continuation) = AsyncStream<AuthenticationOutcome>.makeStream()
        self.continuation = continuation
        return stream
    }

    func emit(_ outcome: AuthenticationOutcome) {
        continuation?.yield(outcome)
    }

    func finish() {
        continuation?.finish()
    }

    // MARK: Private

    private var continuation: AsyncStream<AuthenticationOutcome>.Continuation?

}
