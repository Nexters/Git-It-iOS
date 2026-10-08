import Foundation
import Testing

@testable import DomainUseCaseImplementation
@testable import DomainUseCaseInterface

@Suite("QuizDetail 북마크")
struct QuizDetailBookmarkTests {

    // MARK: Internal

    @Test
    func `북마크와 해제는 각각 저장 상태를 요청한다`() async throws {
        let bookmarks = SpyBookmarkRepository()
        let quizDetail = Self.makeQuizDetail(bookmarks: bookmarks)

        #expect(try await quizDetail.bookmark(
            "q1",
            in: "p1",
        ) == QuizBookmarkState(
            quizID: "q1",
            isBookmarked: true,
        ))
        #expect(try await quizDetail.unbookmark(
            "q1",
            in: "p1",
        ) == QuizBookmarkState(
            quizID: "q1",
            isBookmarked: false,
        ))
    }

    @Test
    func `같은 퀴즈의 북마크 변경은 호출 순서대로 처리한다`() async throws {
        let bookmarks = SpyBookmarkRepository(holdsFirstRequest: true)
        let quizDetail = Self.makeQuizDetail(bookmarks: bookmarks)

        let bookmark = Task { try await quizDetail.bookmark(
            "q1",
            in: "p1",
        ) }
        await Self.settle { await bookmarks.events == ["true:start"] }
        let unbookmark = Task { try await quizDetail.unbookmark(
            "q1",
            in: "p1",
        ) }
        for _ in 0 ..< 50 {
            await Task.yield()
        }
        #expect(await bookmarks.events == ["true:start"])

        await bookmarks.release()
        _ = try await bookmark.value
        _ = try await unbookmark.value

        #expect(await bookmarks.events == ["true:start", "true:end", "false:start", "false:end"])
        #expect(await quizDetail.pendingBookmarkCount == 0)
    }

    @Test
    func `북마크 목록을 필터 그대로 조회한다`() async throws {
        let bookmarks = SpyBookmarkRepository()
        let quizDetail = Self.makeQuizDetail(bookmarks: bookmarks)

        _ = try await quizDetail.bookmarks(.project("p1"))

        #expect(await bookmarks.requestedFilters == [.project("p1")])
    }

    // MARK: Private

    private static func makeQuizDetail(bookmarks: SpyBookmarkRepository) -> QuizDetail {
        QuizDetail(
            quizSetRepository: StubQuizSetRepository(
                quizSet: QuizSet(
                    id: "s1",
                    title: "",
                    description: "",
                    quizzes: [],
                )
            ),
            answerRepository: SpyAnswerRepository(),
            bookmarkRepository: bookmarks,
        )
    }

    private static func settle(until condition: @Sendable () async -> Bool) async {
        for _ in 0 ..< 200 {
            guard await !condition() else { return }
            await Task.yield()
        }
    }

}
