public protocol LearningProjectOutcomesUseCase: Sendable {
    func callAsFunction() async -> AsyncStream<LearningProjectGenerationOutcome>
}
