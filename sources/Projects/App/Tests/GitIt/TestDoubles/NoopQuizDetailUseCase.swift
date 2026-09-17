import DomainIdentifier
import DomainQuizDetail
import Foundation

struct NoopQuizDetailUseCase: QuizDetailUseCase {

    func quizSet(
        _: QuizSetID,
        in _: ProjectID,
    ) async throws -> QuizSet {
        throw QuizDetailError.quizSetUnavailable
    }

    func grade(_: ChoiceAnswer) async throws -> ChoiceGrading {
        throw QuizDetailError.temporarilyUnavailable
    }

    func grade(_: EssayAnswer) async throws -> EssayGrading {
        throw QuizDetailError.temporarilyUnavailable
    }

    func bookmark(
        _: QuizID,
        in _: ProjectID,
    ) async throws -> QuizBookmarkState {
        throw QuizDetailError.temporarilyUnavailable
    }

    func unbookmark(
        _: QuizID,
        in _: ProjectID,
    ) async throws -> QuizBookmarkState {
        throw QuizDetailError.temporarilyUnavailable
    }

    func bookmarks(_: QuizBookmarkFilter) async throws -> QuizBookmarkList {
        QuizBookmarkList(totalCount: 0, projects: [], bookmarks: [])
    }

}
