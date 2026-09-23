import DesignSystem
import SwiftUI
import UIComponent

extension QuizGenerationProgressScreen {
    struct FailureView: View {

        // MARK: Internal

        let bottomButtonPadding: CGFloat
        let onDismiss: () -> Void
        let onRetry: () -> Void

        var body: some View {
            VStack(spacing: LayoutToken.margin) {
                ScreenControlBar(onLeadingTap: onDismiss)
                    .designSystemScreenMargin()

                Spacer(minLength: 0)

                VStack(spacing: Constant.guideStepSpacing) {
                    StyledText(text: LocalizedText.ProjectRegistration.quizGenerationFailureTitle)
                        .textStyle(.subtitle1)
                        .multilineTextAlignment(.center)
                    StyledText(text: LocalizedText.ProjectRegistration.quizGenerationFailureMessage)
                        .textStyle(.body2)
                        .foregroundColorToken(.grey400)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 0)

                FeedbackActionButton(
                    title: LocalizedText.ProjectRegistration.quizGenerationFailureRetryButtonTitle,
                    action: onRetry,
                )
                .designSystemScreenMargin()
                .padding(.bottom, bottomButtonPadding)
            }
        }

        // MARK: Private

        private enum Constant {
            static let guideStepSpacing: CGFloat = 10
        }

    }
}
