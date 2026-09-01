public struct LearningProjectOutcomes: LearningProjectOutcomesUseCase, Sendable {

    // MARK: Lifecycle

    public init(repository: any GenerationOutcomeRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction() async -> AsyncStream<GenerationOutcome> {
        await repository.outcomes()
    }

    // MARK: Private

    private let repository: any GenerationOutcomeRepository

}
