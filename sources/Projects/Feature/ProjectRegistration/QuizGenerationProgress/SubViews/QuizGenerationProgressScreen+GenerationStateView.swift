import DesignSystem
import SwiftUI
import UIComponent

extension QuizGenerationProgressScreen {
    struct GenerationStateView: View {

        // MARK: Internal

        enum State: Equatable, Sendable {
            case generating
            case failed
        }

        let state: State
        let onWaitAtHome: () -> Void
        let onDismiss: () -> Void
        let onRetry: () -> Void

        var body: some View {
            switch state {
            case .generating:
                QuizGenerationProgressScreen.GeneratingView(onWaitAtHome: onWaitAtHome)

            case .failed:
                QuizGenerationProgressScreen.FailureView(
                    bottomButtonPadding: Constant.failureBottomButtonPadding,
                    onDismiss: onDismiss,
                    onRetry: onRetry,
                )
            }
        }

        // MARK: Private

        private enum Constant {
            static let failureBottomButtonPadding: CGFloat = 24
        }

    }
}
