import ComposableArchitecture
import DomainLearningProject
import SwiftUI
import UIComponent

private func previewProject(index: Int) -> LearningProjectSummary {
    LearningProjectSummary(
        projectID: "project-\(index)",
        repositoryName: "0-jerry/git-it-ios-\(index)",
        repositoryImageURL: nil,
        techStack: ["Swift", "SwiftUI", "TCA"],
        currentSetLabel: "CHAPTER \(index)",
        currentSetTitle: "의존성 주입과 모듈 경계",
        nextSetID: "set-\(index)",
        nextQuestionID: "question-\(index)",
        overallProgressPercent: index * 20,
    )
}

private func previewState(
    projects: [LearningProjectSummary] = (1...4).map(previewProject(index:)),
    initialLoad: ProjectListFeature.InitialLoad = .loaded,
    mode: ProjectListFeature.Mode = .browsing,
    deletion: ProjectListFeature.Deletion = .idle,
) -> ProjectListFeature.State {
    var state = ProjectListFeature.State()
    state.projects = projects
    state.initialLoad = initialLoad
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
