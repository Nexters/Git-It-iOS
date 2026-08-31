public struct LearningProjectOutcomes: LearningProjectOutcomesUseCase, Sendable {

    // MARK: Lifecycle

    public init(repository: any LearningProjectGenerationOutcomeRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction() async -> AsyncStream<LearningProjectGenerationOutcome> {
        await repository.outcomes()
    }

    // MARK: Private

    private let repository: any LearningProjectGenerationOutcomeRepository

}
