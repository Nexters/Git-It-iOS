public protocol FetchLearningProjects: Sendable {
    func callAsFunction(
        page: Int,
        size: Int,
    ) async throws -> LearningProjectPage
}
