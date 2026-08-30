public protocol ObserveLearningProjectGenerationOutcomesUseCase: Sendable {
    func callAsFunction() async -> AsyncStream<LearningProjectGenerationOutcome>
}
