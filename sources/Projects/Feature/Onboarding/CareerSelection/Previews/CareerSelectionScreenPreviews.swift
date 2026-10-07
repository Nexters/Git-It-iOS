import ComposableArchitecture
import DomainMember
import SwiftUI

extension CareerSelectionFeature.State {
    fileprivate static func preview(
        careerLevel: CareerLevel? = nil,
        submission: CareerSelectionFeature.Submission = .idle,
    ) -> Self {
        var state = CareerSelectionFeature.State()
        state.careerLevel = careerLevel
        state.submission = submission
        return state
    }
}

#Preview("Career Selection - 미선택 · 737:10358") {
    CareerSelectionScreen(store: Store(initialState: .preview()) { EmptyReducer() })
}

#Preview("Career Selection - 선택됨 · 737:10349") {
    CareerSelectionScreen(store: Store(initialState: .preview(careerLevel: .entry)) { EmptyReducer() })
}

#Preview("Career Selection - 제출 실패") {
    CareerSelectionScreen(
        store: Store(initialState: .preview(careerLevel: .junior, submission: .failed)) { EmptyReducer() }
    )
}
