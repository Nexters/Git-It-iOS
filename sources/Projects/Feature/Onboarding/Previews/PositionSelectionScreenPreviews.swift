import SwiftUI

#Preview("Position Selection - 미선택 · 737:10367") {
    var state = CurationFeature.State()
    state.screen = .position
    return PositionSelectionScreen(store: CurationFeature.previewStore(state))
}

#Preview("Position Selection - 선택됨 · 737:10367") {
    var state = CurationFeature.State()
    state.screen = .position
    state.selection.position = .backend
    return PositionSelectionScreen(store: CurationFeature.previewStore(state))
}

#Preview("Position Selection - 뒤로 가기 실패") {
    var state = CurationFeature.State()
    state.screen = .position
    state.selection.position = .ios
    state.exitStatus = .failed
    return PositionSelectionScreen(store: CurationFeature.previewStore(state))
}
