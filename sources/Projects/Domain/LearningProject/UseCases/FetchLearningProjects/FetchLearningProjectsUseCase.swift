public protocol FetchLearningProjectsUseCase: Sendable {
    func callAsFunction() async throws -> LearningProjectPage
}
