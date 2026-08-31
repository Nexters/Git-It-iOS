import DomainLearningProject
import Foundation

actor LearningProjectOutcomesUseCaseMock: LearningProjectOutcomesUseCase {

    // MARK: Internal

    func callAsFunction() async -> AsyncStream<LearningProjectGenerationOutcome> {
        let (stream, continuation) = AsyncStream<LearningProjectGenerationOutcome>.makeStream()
        self.continuation = continuation
        return stream
    }

    func emit(_ outcome: LearningProjectGenerationOutcome) {
        continuation?.yield(outcome)
    }

    func finish() {
        continuation?.finish()
    }

    // MARK: Private

    private var continuation: AsyncStream<LearningProjectGenerationOutcome>.Continuation?

}
