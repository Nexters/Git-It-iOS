import Foundation

// MARK: - SetQuestionBookmark

public struct SetQuestionBookmark: SetQuestionBookmarkUseCase {

    // MARK: Lifecycle

    public init(
        repository: BookmarkRepository,
        serializer: QuestionMutationSerializer = QuestionMutationSerializer(),
    ) {
        self.repository = repository
        self.serializer = serializer
    }

    // MARK: Public

    public func callAsFunction(
        projectID: String,
        questionID: String,
        bookmarked: Bool,
    ) async throws -> BookmarkState {
        try await serializer.run(key: questionID) {
            try await repository.setBookmark(
                projectID: projectID,
                questionID: questionID,
                bookmarked: bookmarked,
            )
        }
    }

    // MARK: Private

    private let repository: BookmarkRepository
    private let serializer: QuestionMutationSerializer

}
