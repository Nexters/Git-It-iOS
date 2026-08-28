import SwiftUI

#Preview("Career Selection - 미선택 · 737:10358") {
    var state = CurationFeature.State()
    state.screen = .career
    state.selection.position = .ios
    return CareerSelectionScreen(store: CurationFeature.previewStore(state))
}

#Preview("Career Selection - 선택됨 · 737:10349") {
    var state = CurationFeature.State()
    state.screen = .career
    state.selection.position = .ios
    state.selection.careerLevel = .entry
    return CareerSelectionScreen(store: CurationFeature.previewStore(state))
}

#Preview("Career Selection - 제출 실패") {
    var state = CurationFeature.State()
    state.screen = .career
    state.selection.position = .ios
    state.selection.careerLevel = .junior
    state.selection.submission = .failed
    return CareerSelectionScreen(store: CurationFeature.previewStore(state))
}
