import ComposableArchitecture
import SwiftUI
import UIComponent

#Preview("생성 시작 확정 · 737:10830") {
    ScreenContainer {
        QuizGenerationConfirmationScreen(
            store: Store(initialState: QuizGenerationConfirmationFeature.State()) { EmptyReducer() }
        )
    }
}
