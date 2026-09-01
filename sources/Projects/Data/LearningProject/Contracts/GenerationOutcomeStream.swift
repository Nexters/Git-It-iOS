public protocol GenerationOutcomeStream: Sendable {
    func outcomes() -> AsyncStream<GenerationOutcomeDTO>
}
