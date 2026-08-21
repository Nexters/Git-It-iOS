public protocol FetchLearningProjectDetailUseCase: Sendable {
    func callAsFunction(projectID: String) async throws -> LearningProjectDetail
}
