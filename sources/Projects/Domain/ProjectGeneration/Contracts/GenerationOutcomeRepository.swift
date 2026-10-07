public protocol GenerationOutcomeRepository: Sendable {
    func outcomes() async -> AsyncStream<GenerationOutcome>
}
