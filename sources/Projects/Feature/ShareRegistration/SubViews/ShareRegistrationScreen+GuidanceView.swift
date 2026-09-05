import DesignSystem
import SwiftUI
import UIComponent

extension ShareRegistrationScreen {

    /// 링크 오류, 로그인 필요, 앱 실행 필요, 성공, 실패를 본 앱의 안내 화면과 같은 구성으로
    /// 보여 준다. 본 앱을 여는 동작은 제공하지 않는다.
    struct GuidanceView: View {

        // MARK: Internal

        let title: String
        let message: String
        let retryTitle: String?
        let onRetry: () -> Void
        let onDismiss: () -> Void

        var body: some View {
            VStack(spacing: LayoutToken.margin.cgFloatValue) {
                ScreenHeader(style: .default, onLeadingTap: onDismiss)
                    .designSystemScreenMargin()

                Spacer(minLength: 0)

                VStack(spacing: Constant.textSetSpacing) {
                    StyledText.subtitle1(title, alignment: .center)
                    StyledText.body2(message, color: .grey400, alignment: .center)
                }
                .designSystemScreenMargin()
                .accessibilityElement(children: .combine)

                Spacer(minLength: 0)

                VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                    if let retryTitle {
                        ActionButton.primary(retryTitle, action: onRetry)
                    }
                    ActionButton.secondary(ShareRegistrationScreen.dismissTitle, action: onDismiss)
                }
                .designSystemScreenMargin()
                .padding(.bottom, Constant.bottomButtonPadding)
            }
        }

        // MARK: Private

        private enum Constant {
            static let textSetSpacing: CGFloat = 16
            static let bottomButtonPadding: CGFloat = 24
        }

    }

}
