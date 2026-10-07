public protocol FetchLearningProjectsUseCase: Sendable {
    func callAsFunction(page: Int) async throws -> LearningProjectPage
}
