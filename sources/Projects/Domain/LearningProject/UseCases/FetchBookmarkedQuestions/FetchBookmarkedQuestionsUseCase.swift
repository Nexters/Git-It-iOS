public protocol FetchBookmarkedQuestionsUseCase: Sendable {
    func callAsFunction(projectID: String?) async throws -> BookmarkedQuestionCollection
}
