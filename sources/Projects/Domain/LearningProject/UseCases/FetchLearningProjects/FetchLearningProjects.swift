public struct FetchLearningProjects: FetchLearningProjectsUseCase {

    // MARK: Lifecycle

    public init(repository: LearningProjectRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction() async throws -> LearningProjectPage {
        try await repository.fetchProjects(page: Self.compatibilityPage, size: Self.compatibilitySize)
    }

    // MARK: Private

    private static let compatibilityPage = 0
    private static let compatibilitySize = 20

    private let repository: LearningProjectRepository

}
