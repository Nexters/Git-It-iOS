public protocol ProjectGenerationOutcomeRemote: Sendable {
    func outcomes() -> AsyncStream<ProjectGenerationOutcomeDTO>
}
