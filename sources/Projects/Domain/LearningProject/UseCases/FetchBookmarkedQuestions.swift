public struct FetchBookmarkedQuestions: FetchBookmarkedQuestionsUseCase {

    // MARK: Lifecycle

    public init(repository: BookmarkRepository) {
        self.repository = repository
    }

    // MARK: Public

    public func callAsFunction(projectID: String?) async throws -> BookmarkedQuestionCollection {
        try await repository.fetchBookmarkedQuestions(projectID: projectID)
    }

    // MARK: Private

    private let repository: BookmarkRepository

}
