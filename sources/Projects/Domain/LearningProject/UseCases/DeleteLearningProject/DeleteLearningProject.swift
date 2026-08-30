public struct DeleteLearningProject: DeleteLearningProjectUseCase {

    // MARK: Lifecycle

    public init(repository: LearningProjectRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction(projectID: String) async throws {
        try await repository.deleteProject(projectID: projectID)
    }

    // MARK: Private

    private let repository: LearningProjectRepository

}
