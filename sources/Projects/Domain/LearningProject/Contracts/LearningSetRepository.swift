public protocol LearningSetRepository: Sendable {
    func fetchSet(
        projectID: String,
        setID: String,
    ) async throws -> LearningSet
}
