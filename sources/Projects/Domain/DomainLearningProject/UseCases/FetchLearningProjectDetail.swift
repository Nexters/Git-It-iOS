public struct FetchLearningProjectDetail: Sendable {

    // MARK: Lifecycle

    public init(repository: LearningProjectRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction(projectId: String) async throws -> LearningProjectDetail {
        try await repository.fetchProjectDetail(projectId: projectId)
    }

    // MARK: Private

    private let repository: LearningProjectRepository

}
