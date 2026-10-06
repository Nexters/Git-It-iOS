public protocol ObserveGenerationOutcomesUseCase: Sendable {
    func callAsFunction() async -> AsyncStream<GenerationOutcome>
}
