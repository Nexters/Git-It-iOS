public protocol FetchLearningSetUseCase: Sendable {
    func callAsFunction(
        projectID: String,
        setID: String,
    ) async throws -> LearningSet
}
