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

    /// 구독이 확립된 시점을 관찰하기 위한 지원 함수다.
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
