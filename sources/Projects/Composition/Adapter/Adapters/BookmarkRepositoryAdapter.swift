import DataLearningProject
import DomainLearningProject

// MARK: - BookmarkRepositoryAdapter

struct BookmarkRepositoryAdapter: BookmarkRepository {

    // MARK: Lifecycle

    init(remote: BookmarkRemote) {
        self.remote = remote
    }

    // MARK: Internal

    func setBookmark(
        projectID: String,
        questionID: String,
        bookmarked: Bool,
    ) async throws -> BookmarkState {
        do {
            let response = try await remote.setBookmark(
                projectID: projectID,
                questionID: questionID,
                request: BookmarkQuestionRequestDTO(bookmarked: bookmarked),
            )
            return BookmarkState(bookmarked: response.bookmarked)
        } catch let error as DataLearningProjectError {
            throw domainError(for: error)
        }
    }

    func fetchBookmarkedQuestions(projectID: String?) async throws -> BookmarkedQuestionCollection {
        do {
            let response = try await remote.fetchBookmarks(projectID: projectID)
            return BookmarkedQuestionCollection(
                totalCount: response.totalCount,
                availableProjects: response.availableProjects.map(\.projectID),
                bookmarks: response.bookmarks.map {
                    BookmarkedQuestion(
                        projectID: $0.projectID,
                        setID: $0.setID,
                        questionID: $0.questionID,
                        prompt: $0.question,
                    )
                },
            )
        } catch let error as DataLearningProjectError {
            throw domainError(for: error)
        }
    }

    // MARK: Private

    private let remote: BookmarkRemote

    private func domainError(for error: DataLearningProjectError) -> LearningProjectError {
        switch error {
        case .invalidRequest:
            .invalidRequest

        case .unauthorized:
            .unauthorized

        case .projectUnavailable:
            .notFound

        case .questionUnavailable:
            .questionUnavailable

        case .learningSetUnavailable:
            .learningSetUnavailable

        case .temporarilyUnavailable,
             .transport:
            .temporarilyUnavailable

        case .decoding,
             .unexpectedStatus,
             .generationRetryUnavailable:
            .unexpected

        @unknown default:
            .unexpected
        }
    }

}
