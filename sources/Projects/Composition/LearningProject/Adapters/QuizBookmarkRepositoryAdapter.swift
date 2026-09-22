import DataLearningProject
import DomainIdentifier
import DomainQuizDetail

// MARK: - QuizBookmarkRepositoryAdapter

public struct QuizBookmarkRepositoryAdapter: BookmarkRepository {

    // MARK: Lifecycle

    public init(remote: BookmarkRemote) {
        self.remote = remote
    }

    // MARK: Public

    public func setBookmark(
        _ quizID: QuizID,
        in projectID: ProjectID,
        isBookmarked: Bool,
    ) async throws -> QuizBookmarkState {
        do {
            let response = try await remote.setBookmark(
                projectID: projectID,
                questionID: quizID,
                request: BookmarkQuestionRequestDTO(bookmarked: isBookmarked),
            )
            return QuizBookmarkState(
                quizID: quizID,
                isBookmarked: response.bookmarked,
            )
        } catch let error as LearningProjectServiceError {
            throw domainError(for: error)
        }
    }

    public func bookmarks(_ filter: QuizBookmarkFilter) async throws -> QuizBookmarkList {
        do {
            let response = try await remote.fetchBookmarks(projectID: projectID(for: filter))
            return QuizBookmarkList(
                totalCount: response.totalCount,
                projects: response.availableProjects.map {
                    QuizBookmarkProject(
                        id: $0.projectID,
                        name: $0.repositoryName,
                    )
                },
                bookmarks: response.bookmarks.map {
                    QuizBookmark(
                        projectID: $0.projectID,
                        projectName: $0.projectName,
                        setID: $0.setID,
                        setLabel: $0.setLabel,
                        problemNumber: $0.problemNumber,
                        quizID: $0.questionID,
                        prompt: $0.question,
                    )
                },
            )
        } catch let error as LearningProjectServiceError {
            throw domainError(for: error)
        }
    }

    // MARK: Private

    private let remote: BookmarkRemote

    private func projectID(for filter: QuizBookmarkFilter) -> ProjectID? {
        switch filter {
        case .all: nil
        case .project(let projectID): projectID
        }
    }

    private func domainError(for error: LearningProjectServiceError) -> QuizDetailError {
        switch error {
        case .invalidRequest:
            .invalidAnswer

        case .unauthorized:
            .unauthorized

        case .projectUnavailable:
            .notFound

        case .questionUnavailable:
            .quizUnavailable

        case .learningSetUnavailable:
            .quizSetUnavailable

        case .temporarilyUnavailable,
             .transport:
            .temporarilyUnavailable

        case .unexpectedStatus:
            .unexpected

        @unknown default:
            .unexpected
        }
    }

}
