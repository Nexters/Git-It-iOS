import ComposableArchitecture
import DomainProject
import DomainQuizDetail
import SwiftUI

private let previewQuiz = Quiz(
    id: "quiz-0",
    prompt: "Composition 패키지가 Domain에 의존해도 되는 이유는 무엇인가?",
    content: .choice(
        options: ["의존 방향이 단방향이기 때문", "진입점이기 때문", "UI를 포함하기 때문", "제약이 없기 때문"],
        submitted: nil,
    ),
    sources: [],
)

private let previewDetail = ProjectDetail(
    id: "project-1",
    repository: ProjectRepositoryInfo(
        url: "https://github.com/owner/repo",
        name: "owner/repo",
        imageURL: nil,
        starCount: 1_284,
        techStack: ["Swift", "SwiftUI"],
    ),
    progressPercent: 45,
    sets: [
        ProjectSetProgress(
            setID: "set-0",
            label: "CHAPTER 1",
            title: "모듈 경계와 의존성",
            quizCount: 5,
            completedCount: 2,
        )
    ],
    next: nil,
)

private let previewBookmarks = QuizBookmarkList(
    totalCount: 1,
    projects: [QuizBookmarkProject(
        id: "project-1",
        name: "owner/repo",
    )],
    bookmarks: [
        QuizBookmark(
            projectID: "project-1",
            projectName: "owner/repo",
            setID: "set-0",
            setLabel: "Set 1",
            problemNumber: 1,
            quizID: "quiz-0",
            prompt: "Composition 패키지가 Domain에 의존해도 되는 이유는 무엇인가?",
        )
    ],
)

private func previewState(
    activeScreen: ProjectDetailRouterFeature.ActiveScreen,
    preparation: SingleQuestionEntryFeature.Preparation = .idle,
) -> ProjectDetailRouterFeature.State {
    var state = ProjectDetailRouterFeature.State(projectID: "project-1")
    state.projectDetail.detailLoad.detail = previewDetail
    state.projectDetail.detailLoad.loadStatus = .loaded
    state.savedQuestions.collection = previewBookmarks
    state.savedQuestions.loadStatus = .loaded
    state.singleQuestion = QuestionSolvingFeature.State(
        projectID: "project-1",
        question: previewQuiz,
        advanceActionTitle: ProjectDetailRouterFeature.singleQuestionAdvanceActionTitle,
        isBookmarked: true,
    )
    state.singleQuestionEntry.preparation = preparation
    state.activeScreen = activeScreen
    return state
}

#Preview("상세 흐름 · 프로젝트 상세") {
    ProjectDetailRouter(
        store: Store(initialState: previewState(activeScreen: .projectDetail)) { EmptyReducer() }
    )
}

#Preview("상세 흐름 · 저장한 문제") {
    ProjectDetailRouter(
        store: Store(initialState: previewState(activeScreen: .savedQuestions)) { EmptyReducer() }
    )
}

#Preview("상세 흐름 · 단일 문제") {
    ProjectDetailRouter(
        store: Store(initialState: previewState(activeScreen: .singleQuestion)) { EmptyReducer() }
    )
}

#Preview("상세 흐름 · 진입 실패 alert") {
    ProjectDetailRouter(
        store: Store(
            initialState: previewState(
                activeScreen: .savedQuestions,
                preparation: .failed(.quizUnavailable),
            )
        ) { EmptyReducer() }
    )
}
