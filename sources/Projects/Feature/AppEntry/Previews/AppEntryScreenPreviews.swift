import SwiftUI

#Preview("AppEntry - 세션 확인 중") {
    AppEntryScreen(store: AppEntryFeature.previewStore(.init()))
}

#Preview("AppEntry - 복구 오류") {
    var state = AppEntryFeature.State()
    state.authentication = .retryableFailure
    return AppEntryScreen(store: AppEntryFeature.previewStore(state))
}
