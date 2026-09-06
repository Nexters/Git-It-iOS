import ComposableArchitecture
import DomainMember
import SwiftUI

extension PositionSelectionFeature.State {
    fileprivate static func preview(
        position: MemberPosition? = nil,
        exitStatus: PositionSelectionFeature.ExitStatus = .idle,
    ) -> Self {
        var state = PositionSelectionFeature.State()
        state.position = position
        state.exitStatus = exitStatus
        return state
    }
}

#Preview("Position Selection - 미선택 · 737:10367") {
    PositionSelectionScreen(store: Store(initialState: .preview()) { EmptyReducer() })
}

#Preview("Position Selection - 선택됨 · 737:10367") {
    PositionSelectionScreen(store: Store(initialState: .preview(position: .backend)) { EmptyReducer() })
}

#Preview("Position Selection - 뒤로 가기 실패") {
    PositionSelectionScreen(
        store: Store(initialState: .preview(position: .ios, exitStatus: .failed)) { EmptyReducer() }
    )
}
