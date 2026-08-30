public struct FetchLearningSet: FetchLearningSetUseCase {

    // MARK: Lifecycle

    public init(repository: LearningSetRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction(
        projectID: String,
        setID: String,
    ) async throws -> LearningSet {
        try await repository.fetchSet(projectID: projectID, setID: setID)
    }

    // MARK: Private

    private let repository: LearningSetRepository

}
