import ComposableArchitecture
import SwiftUI
import UIComponent

extension QuizGenerationProgressFeature.State {
    fileprivate static func preview(progress: QuizGenerationProgressFeature.RegistrationProgress) -> Self {
        var state = QuizGenerationProgressFeature.State()
        state.progress = progress
        return state
    }
}

#Preview("생성 진행 · 2026:29388") {
    ScreenContainer { _ in
        QuizGenerationProgressScreen(
            store: Store(
                initialState: .preview(
                    progress: .awaitingOutcome(ProjectRegistrationPreviewSupport.receipt)
                )
            ) { EmptyReducer() }
        )
    }
}

#Preview("생성 실패") {
    ScreenContainer { _ in
        QuizGenerationProgressScreen(
            store: Store(initialState: .preview(progress: .failed(.unexpected))) { EmptyReducer() }
        )
    }
}

#Preview("알림 옵션 시트 · 824:12149") {
    QuizGenerationProgressScreen.GenerationReminderSheet(onAccept: { }, onDecline: { })
}
