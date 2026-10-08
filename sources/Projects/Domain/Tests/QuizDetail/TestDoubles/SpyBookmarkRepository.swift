@testable import DomainQuizDetail

actor SpyBookmarkRepository: BookmarkRepository {

    // MARK: Lifecycle

    init(holdsFirstRequest: Bool = false) {
        holdsRequest = holdsFirstRequest
    }

    // MARK: Internal

    private(set) var events = [String]()
    private(set) var requestedFilters = [QuizBookmarkFilter]()

    func setBookmark(
        _ quizID: String,
        in _: String,
        isBookmarked: Bool,
    ) async throws -> QuizBookmarkState {
        events.append("\(isBookmarked):start")
        if holdsRequest {
            await withCheckedContinuation { waiter = $0 }
        }
        events.append("\(isBookmarked):end")
        return QuizBookmarkState(
            quizID: quizID,
            isBookmarked: isBookmarked,
        )
    }

    func bookmarks(_ filter: QuizBookmarkFilter) async throws -> QuizBookmarkList {
        requestedFilters.append(filter)
        return QuizBookmarkList(
            totalCount: 0,
            projects: [],
            bookmarks: [],
        )
    }

    func release() {
        holdsRequest = false
        waiter?.resume()
        waiter = nil
    }

    // MARK: Private

    private var holdsRequest: Bool
    private var waiter: CheckedContinuation<Void, Never>?

}
