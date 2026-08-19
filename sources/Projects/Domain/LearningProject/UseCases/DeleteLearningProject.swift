public protocol DeleteLearningProject: Sendable {
    func callAsFunction(_ id: LearningProjectID) async throws
}
