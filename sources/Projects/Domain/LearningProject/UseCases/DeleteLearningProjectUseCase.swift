public protocol DeleteLearningProjectUseCase: Sendable {
    func callAsFunction(projectId: String) async throws
}
