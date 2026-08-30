public protocol LearningProjectGenerationOutcomeRepository: Sendable {
    func outcomes() async -> AsyncStream<LearningProjectGenerationOutcome>
}
