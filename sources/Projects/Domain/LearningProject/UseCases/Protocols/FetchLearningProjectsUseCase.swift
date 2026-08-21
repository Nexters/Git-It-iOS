public protocol FetchLearningProjectsUseCase: Sendable {
    func callAsFunction(
        page: Int,
        size: Int,
    ) async throws -> LearningProjectPage
}
