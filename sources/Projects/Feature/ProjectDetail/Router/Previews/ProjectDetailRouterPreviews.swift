import ComposableArchitecture
import DomainLearningProject
import SwiftUI

private let previewQuestion = Question(
    questionID: "question-0",
    prompt: "Composition 패키지가 Domain에 의존해도 되는 이유는 무엇인가?",
    format: .multipleChoice,
    choices: ["의존 방향이 단방향이기 때문", "진입점이기 때문", "UI를 포함하기 때문", "제약이 없기 때문"],
    sources: [],
    myAnswer: nil,
)

private let previewDetail = LearningProjectDetail(
    projectID: "project-1",
    repositoryURL: "https://github.com/owner/repo",
    repositoryName: "owner/repo",
    repositoryImageURL: nil,
    starCount: 1_284,
    techStack: ["Swift", "SwiftUI"],
    overallProgressPercent: 45,
    nextQuestionID: nil,
    sets: [
        LearningProjectSetProgress(
            setID: "set-0",
            label: "CHAPTER 1",
            title: "모듈 경계와 의존성",
            problemCount: 5,
            completedCount: 2,
        )
    ],
)

private let previewCollection = BookmarkedQuestionCollection(
    totalCount: 1,
    availableProjects: [BookmarkedProject(id: "project-1", name: "owner/repo")],
    bookmarks: [
        BookmarkedQuestion(
            projectID: "project-1",
            projectName: "owner/repo",
            setID: "set-0",
            setLabel: "Set 1",
            problemNumber: 1,
            questionID: "question-0",
            prompt: "Composition 패키지가 Domain에 의존해도 되는 이유는 무엇인가?",
        )
    ],
)

private func previewState(
    activeScreen: ProjectDetailRouterFeature.ActiveScreen,
    preparation: SingleQuestionEntryFeature.Preparation = .idle,
) -> ProjectDetailRouterFeature.State {
    var state = ProjectDetailRouterFeature.State(projectID: "project-1")
    state.projectDetail.detail = previewDetail
    state.projectDetail.loadStatus = .loaded
    state.savedQuestions.collection = previewCollection
    state.savedQuestions.loadStatus = .loaded
    state.singleQuestion = QuestionSolvingFeature.State(
        projectID: "project-1",
        question: previewQuestion,
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
                preparation: .failed(.questionUnavailable),
            )
        ) { EmptyReducer() }
    )
}
