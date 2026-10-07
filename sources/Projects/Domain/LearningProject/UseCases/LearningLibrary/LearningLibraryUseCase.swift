public protocol LearningLibraryUseCase: Sendable {
    func project(id: String) async throws -> LearningProjectDetail
    func deleteProject(id: String) async throws
    func learningSet(
        projectID: String,
        setID: String,
    ) async throws -> LearningSet
    func bookmarkedQuestions(projectID: String?) async throws -> BookmarkedQuestionCollection
}
