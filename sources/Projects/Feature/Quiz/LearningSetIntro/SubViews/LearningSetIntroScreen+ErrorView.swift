import DesignSystem
import SwiftUI
import UIComponent

extension LearningSetIntroScreen {
    struct ErrorView: View {

        // MARK: Internal

        let bottomButtonPadding: CGFloat
        let onBack: () -> Void
        let onRetry: () -> Void

        var body: some View {
            VStack(spacing: LayoutToken.margin) {
                ScreenControlBar(onLeadingTap: onBack)
                    .designSystemScreenMargin()

                Spacer(minLength: 0)

                VStack(spacing: Constant.textSpacing) {
                    StyledText(text: "학습 세트를 불러오지 못했어요", style: .subtitle1, alignment: .center)
                    StyledText(text: "잠시 후 다시 시도해 주세요.", style: .body2, color: .grey400, alignment: .center)
                }

                Spacer(minLength: 0)

                FeedbackActionButton(title: "다시 시도하기", style: .primary, action: onRetry)
                    .designSystemScreenMargin()
                    .padding(.bottom, bottomButtonPadding)
            }
        }

        // MARK: Private

        private enum Constant {
            static let textSpacing: CGFloat = 10
        }

    }
}
