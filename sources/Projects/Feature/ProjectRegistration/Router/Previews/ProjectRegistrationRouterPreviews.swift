import ComposableArchitecture
import SwiftUI
import UIComponent

extension ProjectRegistrationRouterFeature.State {
    fileprivate static func preview(activeScreen: ProjectRegistrationRouterFeature.ActiveScreen) -> Self {
        var state = ProjectRegistrationRouterFeature.State()
        state.activeScreen = activeScreen
        state.repositoryConfirmation.repository = ProjectRegistrationPreviewSupport.repository
        return state
    }
}

#Preview("링크 입력 · 986:13739") {
    ProjectRegistrationRouter(
        store: Store(initialState: .preview(activeScreen: .repositoryLinkInput)) { EmptyReducer() }
    )
}

#Preview("레포지토리 확인 · 737:10890") {
    ProjectRegistrationRouter(
        store: Store(initialState: .preview(activeScreen: .repositoryConfirmation)) { EmptyReducer() }
    )
}

#Preview("이해도 선택 · 737:10882") {
    ProjectRegistrationRouter(
        store: Store(initialState: .preview(activeScreen: .quizLevelSelection)) { EmptyReducer() }
    )
}

#Preview("생성 시작 확정 · 737:10830") {
    ProjectRegistrationRouter(
        store: Store(initialState: .preview(activeScreen: .quizGenerationConfirmation)) { EmptyReducer() }
    )
}
