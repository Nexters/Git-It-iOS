import ComposableArchitecture
import SwiftUI
import UIComponent

#Preview("학습 완료 · s13") {
    ScreenContainer {
        LearningCompletionScreen(
            store: Store(
                initialState: LearningCompletionFeature.State(
                    projectID: "project-1",
                    correctChoiceCount: 4,
                    choiceQuestionCount: 5,
                )
            ) { EmptyReducer() }
        )
    }
}

#Preview("학습 완료 · 점수 없음") {
    ScreenContainer {
        LearningCompletionScreen(
            store: Store(
                initialState: LearningCompletionFeature.State(projectID: "project-1")
            ) { EmptyReducer() }
        )
    }
}
