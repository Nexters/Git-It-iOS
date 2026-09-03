import ComposableArchitecture
import DomainLearningProject
import SwiftUI
import UIComponent

private let previewSet = LearningSet(
    setID: "set-1",
    title: "의존성 주입과 모듈 경계",
    description: "이 세트에서는 모듈 사이의 의존 방향과 주입 지점을 확인합니다.",
    questions: [],
)

private func previewState(
    setLoad: LearningSetIntroFeature.SetLoad,
    isEmptySetReported: Bool = false,
) -> LearningSetIntroFeature.State {
    var state = LearningSetIntroFeature.State(projectID: "project-1", setID: "set-1", label: "CHAPTER 1")
    state.setLoad = setLoad
    state.isEmptySetReported = isEmptySetReported
    return state
}

#Preview("세트 소개 · s02") {
    ScreenContainer { _ in
        LearningSetIntroScreen(
            store: Store(initialState: previewState(setLoad: .loaded(previewSet))) { EmptyReducer() }
        )
    }
}

#Preview("세트 소개 · 로딩") {
    ScreenContainer { _ in
        LearningSetIntroScreen(
            store: Store(initialState: previewState(setLoad: .loading(requestID: 1))) { EmptyReducer() }
        )
    }
}

#Preview("세트 소개 · 실패") {
    ScreenContainer { _ in
        LearningSetIntroScreen(
            store: Store(initialState: previewState(setLoad: .failed(.temporarilyUnavailable))) { EmptyReducer() }
        )
    }
}

#Preview("세트 소개 · 문제 없음") {
    ScreenContainer { _ in
        LearningSetIntroScreen(
            store: Store(
                initialState: previewState(setLoad: .loaded(previewSet), isEmptySetReported: true)
            ) { EmptyReducer() }
        )
    }
}
