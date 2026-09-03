import ComposableArchitecture
import DomainLearningProject
import SwiftUI
import UIComponent

#Preview("이해도 선택 · 737:10882") {
    ScreenContainer { _ in
        QuizLevelSelectionScreen(
            store: Store(initialState: QuizLevelSelectionFeature.State()) { EmptyReducer() }
        )
    }
}

#Preview("이해도 선택 · 선택됨 · 737:10874") {
    ScreenContainer { _ in
        QuizLevelSelectionScreen(
            store: Store(initialState: QuizLevelSelectionFeature.State(quizLevel: .l3)) { EmptyReducer() }
        )
    }
}
