public protocol QuizGenerationOutcomeSource: Sendable {
    func outcomes() -> AsyncStream<QuizGenerationOutcomeDTO>
}
