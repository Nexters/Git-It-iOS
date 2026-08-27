public protocol DeleteLearningProjectUseCase: Sendable {
    func callAsFunction(projectID: String) async throws
}
