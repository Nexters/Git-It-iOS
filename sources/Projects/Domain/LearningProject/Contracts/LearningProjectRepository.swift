public protocol LearningProjectRepository: Sendable {
    func register(
        githubRepoURL: String,
        quizLevel: QuizLevel,
    ) async throws -> ProjectRegistrationReceipt
    func fetchProjects(
        page: Int,
        size: Int,
    ) async throws -> LearningProjectPage
    func fetchProjectDetail(projectID: String) async throws -> LearningProjectDetail
    func deleteProject(projectID: String) async throws
}
