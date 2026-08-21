public protocol LearningSetRemote: Sendable {
    func fetchLearningSet(
        projectID: String,
        setID: String,
    ) async throws -> LearningSetResponseDTO
}
