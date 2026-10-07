import ComposableArchitecture
import DomainProject
import SwiftUI
import UIComponent

private func previewProject(index: Int) -> ProjectSummary {
    ProjectSummary(
        id: "project-\(index)",
        repositoryName: "0-jerry/git-it-ios-\(index)",
        repositoryImageURL: nil,
        techStack: ["Swift", "SwiftUI", "TCA"],
        currentSet: ProjectSetLabel(label: "CHAPTER \(index)", title: "의존성 주입과 모듈 경계"),
        next: ProjectNextQuiz(setID: "set-\(index)", quizID: "quiz-\(index)"),
        progressPercent: index * 20,
    )
}

private func previewState(
    projects: [ProjectSummary] = (1...4).map(previewProject(index:)),
    initialLoad: ProjectListFeature.InitialLoad = .loaded,
    pagination: ProjectListFeature.Pagination = .exhausted,
    mode: ProjectListFeature.Mode = .browsing,
    deletion: ProjectListFeature.Deletion = .idle,
) -> ProjectListFeature.State {
    var state = ProjectListFeature.State()
    state.projects = projects
    state.initialLoad = initialLoad
    state.pagination = pagination
    state.mode = mode
    state.deletion = deletion
    return state
}

private func previewStore(_ state: ProjectListFeature.State) -> StoreOf<ProjectListFeature> {
    Store(initialState: state) { EmptyReducer() }
}

#Preview("프로젝트 목록") {
    ProjectListScreen(store: previewStore(previewState()))
}

#Preview("프로젝트 목록 · 메뉴 열림") {
    ProjectListScreen(store: previewStore(previewState(mode: .menuPresented)))
}

#Preview("프로젝트 목록 · 삭제 모드") {
    ProjectListScreen(store: previewStore(previewState(mode: .deleting)))
}

#Preview("프로젝트 목록 · 삭제 확인") {
    ProjectListScreen(
        store: previewStore(previewState(mode: .deleting, deletion: .confirming(projectID: "project-1")))
    )
}

#Preview("프로젝트 목록 · 빈 상태") {
    ProjectListScreen(store: previewStore(previewState(projects: [], initialLoad: .loaded)))
}

#Preview("프로젝트 목록 · 실패") {
    ProjectListScreen(
        store: previewStore(previewState(projects: [], initialLoad: .failed(.temporarilyUnavailable)))
    )
}

#Preview("프로젝트 목록 · 다음 페이지 조회 중") {
    ProjectListScreen(store: previewStore(previewState(pagination: .loading)))
}

#Preview("프로젝트 목록 · 다음 페이지 실패") {
    ProjectListScreen(
        store: previewStore(previewState(pagination: .failed(.temporarilyUnavailable)))
    )
}
