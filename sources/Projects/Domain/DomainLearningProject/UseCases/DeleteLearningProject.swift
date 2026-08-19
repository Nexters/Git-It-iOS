public struct DeleteLearningProject: Sendable {

    // MARK: Lifecycle

    public init(repository: LearningProjectRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction(projectId: String) async throws {
        try await repository.deleteProject(projectId: projectId)
    }

    // MARK: Private

    private let repository: LearningProjectRepository

}
