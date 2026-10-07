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
            VStack(spacing: LayoutToken.margin.cgFloatValue) {
                ScreenHeader(style: .largeTitle, onLeadingTap: onDismiss)
                    .designSystemScreenMargin()

                Spacer(minLength: 0)

                VStack(spacing: Constant.guideStepSpacing) {
                    StyledText.subtitle1("학습 세트를 만들지 못했어요", alignment: .center)
                    StyledText.body2("잠시 후 다시 시도해 주세요.", color: .grey400, alignment: .center)
                }

                Spacer(minLength: 0)

                ActionButton.primary("다시 시도하기", action: onRetry)
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
