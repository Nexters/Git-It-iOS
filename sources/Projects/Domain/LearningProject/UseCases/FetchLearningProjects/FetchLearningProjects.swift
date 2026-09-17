public struct FetchLearningProjects: FetchLearningProjectsUseCase {

    // MARK: Lifecycle

    public init(
        repository: LearningProjectRepository,
        pendingGenerations: any PendingGenerationRepository,
    ) {
        self.repository = repository
        self.pendingGenerations = pendingGenerations
    }

    // MARK: Public

    public func callAsFunction(page: Int) async throws -> LearningProjectPage {
        let loaded = try await repository.fetchProjects(page: page, size: Self.pageSize)
        let creatingProjectIDs = await pendingGenerations.pendingState().activeProjectIDs
        guard !creatingProjectIDs.isEmpty else { return loaded }

        return LearningProjectPage(
            items: loaded.items.filter { !creatingProjectIDs.contains($0.projectID) },
            hasNext: loaded.hasNext,
        )
    }

    // MARK: Private

    private static let pageSize = 20

    private let repository: LearningProjectRepository
    private let pendingGenerations: any PendingGenerationRepository

}
