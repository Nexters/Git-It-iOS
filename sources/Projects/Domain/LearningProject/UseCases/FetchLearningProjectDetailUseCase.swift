public protocol FetchLearningProjectDetailUseCase: Sendable {
    func callAsFunction(projectId: String) async throws -> LearningProjectDetail
}
