import ComposableArchitecture
import SwiftUI
import UIComponent

private extension RepositoryLinkInputFeature.State {
    static func preview(
        repositoryURLInput: String = "",
        validation: RepositoryLinkInputFeature.ValidationStatus = .idle,
    ) -> Self {
        var state = RepositoryLinkInputFeature.State()
        state.repositoryURLInput = repositoryURLInput
        state.validation = validation
        return state
    }
}

#Preview("링크 입력 · 986:13739") {
    ScreenContainer { _ in
        RepositoryLinkInputScreen(store: Store(initialState: .preview()) { EmptyReducer() })
    }
}

#Preview("링크 입력 · 검증 실패") {
    ScreenContainer { _ in
        RepositoryLinkInputScreen(
            store: Store(
                initialState: .preview(
                    repositoryURLInput: "https://github.com/invalid",
                    validation: .failed,
                )
            ) { EmptyReducer() }
        )
    }
}
