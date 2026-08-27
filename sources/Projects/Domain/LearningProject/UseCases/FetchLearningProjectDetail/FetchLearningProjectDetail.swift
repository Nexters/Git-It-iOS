public struct FetchLearningProjectDetail: FetchLearningProjectDetailUseCase {

    // MARK: Lifecycle

    public init(repository: LearningProjectRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction(projectID: String) async throws -> LearningProjectDetail {
        try await repository.fetchProjectDetail(projectID: projectID)
    }

    // MARK: Private

    private let repository: LearningProjectRepository

}
