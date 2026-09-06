public struct FetchLearningProjects: FetchLearningProjectsUseCase {

    // MARK: Lifecycle

    public init(
        repository: LearningProjectRepository,
        creationStateRepository: RepositoryCreationStateRepository,
    ) {
        self.repository = repository
        self.creationStateRepository = creationStateRepository
    }

    // MARK: Public

    public func callAsFunction() async throws -> LearningProjectPage {
        let page = try await repository.fetchProjects(page: Self.compatibilityPage, size: Self.compatibilitySize)
        let creatingProjectIDs = await creationStateRepository.activeProjectIDs()
        guard !creatingProjectIDs.isEmpty else { return page }

        return LearningProjectPage(
            items: page.items.filter { !creatingProjectIDs.contains($0.projectID) },
            hasNext: page.hasNext,
        )
    }

    // MARK: Private

    private static let compatibilityPage = 0
    private static let compatibilitySize = 20

    private let repository: LearningProjectRepository
    private let creationStateRepository: RepositoryCreationStateRepository

}
