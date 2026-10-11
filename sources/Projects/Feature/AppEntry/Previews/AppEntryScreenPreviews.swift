import ComposableArchitecture
import SwiftUI

#Preview("AppEntry - 세션 확인 중") {
    AppEntryScreen(store: Store(initialState: AppEntryFeature.State()) { EmptyReducer() })
}

#Preview("AppEntry - 복구 오류") {
    AppEntryScreen(
        store: Store(
            initialState: {
                var state = AppEntryFeature.State()
                state.authentication = .retryableFailure
                return state
            }()
        ) { EmptyReducer() }
    )
}
