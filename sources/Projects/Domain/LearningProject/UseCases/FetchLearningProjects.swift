public struct FetchLearningProjects: FetchLearningProjectsUseCase {

    // MARK: Lifecycle

    public init(repository: LearningProjectRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction(
        page: Int = 0,
        size: Int = 10,
    ) async throws -> LearningProjectPage {
        try await repository.fetchProjects(page: page, size: size)
    }

    // MARK: Private

    private let repository: LearningProjectRepository

}
