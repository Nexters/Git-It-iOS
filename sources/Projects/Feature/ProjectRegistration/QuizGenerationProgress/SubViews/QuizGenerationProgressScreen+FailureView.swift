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
                    StyledText(text: "학습 세트를 만들지 못했어요")
                        .textStyle(.subtitle1)
                        .multilineTextAlignment(.center)
                    StyledText(text: "잠시 후 다시 시도해 주세요.")
                        .textStyle(.body2)
                        .foregroundColorToken(.grey400)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 0)

                FeedbackActionButton(title: "다시 시도하기", action: onRetry)
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
