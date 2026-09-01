import DomainLearningProject
import Foundation

actor LearningProjectOutcomesUseCaseMock: LearningProjectOutcomesUseCase {

    // MARK: Internal

    func callAsFunction() async -> AsyncStream<GenerationOutcome> {
        let (stream, continuation) = AsyncStream<GenerationOutcome>.makeStream()
        self.continuation = continuation
        return stream
    }

    func emit(_ outcome: GenerationOutcome) {
        continuation?.yield(outcome)
    }

    func finish() {
        continuation?.finish()
    }

    // MARK: Private

    private var continuation: AsyncStream<GenerationOutcome>.Continuation?

}
