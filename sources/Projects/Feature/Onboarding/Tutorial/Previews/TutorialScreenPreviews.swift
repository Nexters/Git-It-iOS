import ComposableArchitecture
import SwiftUI

extension TutorialFeature.State {
    fileprivate static func preview(
        page: Int,
        authentication: TutorialFeature.AuthenticationStatus = .idle,
    ) -> Self {
        var state = TutorialFeature.State(bundleVersion: "1.0.0")
        state.page = page
        state.authentication = authentication
        return state
    }
}

#Preview("Tutorial - 1페이지 · 779:33450") {
    TutorialScreen(store: Store(initialState: .preview(page: 1)) { EmptyReducer() })
}

#Preview("Tutorial - 2페이지 · 779:33529") {
    TutorialScreen(store: Store(initialState: .preview(page: 2)) { EmptyReducer() })
}

#Preview("Tutorial - 3페이지 로그인 · 779:33564") {
    TutorialScreen(store: Store(initialState: .preview(page: 3)) { EmptyReducer() })
}

#Preview("Tutorial - 로그인 취소") {
    TutorialScreen(
        store: Store(initialState: .preview(page: 3, authentication: .cancelled)) { EmptyReducer() }
    )
}
