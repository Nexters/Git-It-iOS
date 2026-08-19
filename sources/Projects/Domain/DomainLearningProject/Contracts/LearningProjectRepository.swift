public protocol LearningProjectRepository: Sendable {
    func register(
        githubRepoUrl: String,
        quizLevel: QuizLevel,
    ) async throws -> LearningProjectRegistration
    func fetchProjects(
        page: Int,
        size: Int,
    ) async throws -> LearningProjectPage
    func fetchProjectDetail(projectId: String) async throws -> LearningProjectDetail
    func deleteProject(projectId: String) async throws
}
