import ComposableArchitecture
import DomainLearningProject
import SwiftUI
import UIComponent

private func previewDetail(sets: [LearningProjectSetProgress]) -> LearningProjectDetail {
    LearningProjectDetail(
        projectID: "project-1",
        repositoryURL: "https://github.com/owner/repo",
        repositoryName: "owner/repo",
        repositoryImageURL: nil,
        starCount: 1_284,
        techStack: ["Swift", "SwiftUI"],
        overallProgressPercent: 45,
        nextQuestionID: nil,
        sets: sets,
    )
}

private let previewSets = [
    LearningProjectSetProgress(
        setID: "set-0",
        label: "CHAPTER 1",
        title: "모듈 경계와 의존성",
        problemCount: 5,
        completedCount: 5,
    ),
    LearningProjectSetProgress(
        setID: "set-1",
        label: "CHAPTER 2",
        title: "상태 관리와 Effect",
        problemCount: 4,
        completedCount: 2,
    ),
    LearningProjectSetProgress(
        setID: "set-2",
        label: "CHAPTER 3",
        title: "테스트 전략",
        problemCount: 3,
        completedCount: 0,
    ),
]

private func previewState(
    detail: LearningProjectDetail? = previewDetail(sets: previewSets),
    loadStatus: ProjectDetailFeature.LoadStatus = .loaded,
    isMenuPresented: Bool = false,
    deletion: ProjectDetailFeature.Deletion = .idle,
) -> ProjectDetailFeature.State {
    var state = ProjectDetailFeature.State(projectID: "project-1")
    state.detail = detail
    state.loadStatus = loadStatus
    state.isMenuPresented = isMenuPresented
    state.deletion = deletion
    return state
}

#Preview("프로젝트 상세 · s01") {
    ProjectDetailScreen(
        store: Store(initialState: previewState()) { EmptyReducer() }
    )
}

#Preview("프로젝트 상세 · 메뉴 펼침") {
    ProjectDetailScreen(
        store: Store(initialState: previewState(isMenuPresented: true)) { EmptyReducer() }
    )
}

#Preview("프로젝트 상세 · 삭제 확인") {
    ProjectDetailScreen(
        store: Store(initialState: previewState(deletion: .confirming)) { EmptyReducer() }
    )
}

#Preview("프로젝트 상세 · 빈 상태") {
    ProjectDetailScreen(
        store: Store(
            initialState: previewState(detail: previewDetail(sets: []))
        ) { EmptyReducer() }
    )
}

#Preview("프로젝트 상세 · 실패") {
    ProjectDetailScreen(
        store: Store(
            initialState: previewState(detail: nil, loadStatus: .failed(.temporarilyUnavailable))
        ) { EmptyReducer() }
    )
}
