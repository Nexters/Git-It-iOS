import DomainLearningProject

actor StubObserveGenerationOutcomesUseCase: ObserveGenerationOutcomesUseCase {

    // MARK: Internal

    func callAsFunction() async -> AsyncStream<GenerationOutcome> {
        let (stream, continuation) = AsyncStream<GenerationOutcome>.makeStream()
        self.continuation = continuation
        subscriptionCount += 1
        return stream
    }

    func emit(_ outcome: GenerationOutcome) {
        continuation?.yield(outcome)
    }

    func finish() {
        continuation?.finish()
    }

    func hasEstablishedSubscription() -> Bool {
        continuation != nil
    }

    func establishedSubscriptionCount() -> Int {
        subscriptionCount
    }

    // MARK: Private

    private var continuation: AsyncStream<GenerationOutcome>.Continuation?
    private var subscriptionCount = 0

}
