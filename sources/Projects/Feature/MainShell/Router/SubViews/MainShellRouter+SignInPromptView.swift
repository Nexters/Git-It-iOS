import DesignSystem
import SwiftUI
import UIComponent

extension MainShellRouter {
    struct SignInPromptView: View {

        // MARK: Internal

        let onSignIn: () -> Void

        var body: some View {
            ScreenContainer {
                VStack(spacing: LayoutToken.compactSpacing) {
                    Spacer()
                    StyledText(text: Constant.title)
                        .textStyle(.subtitle1)
                        .multilineTextAlignment(.center)
                    StyledText(text: Constant.message)
                        .textStyle(.body2)
                        .multilineTextAlignment(.center)
                    Spacer()
                    AppleSignInButton(action: onSignIn)
                        .padding(.bottom, LayoutToken.margin)
                }
                .designSystemScreenMargin()
            }
        }

        // MARK: Private

        private enum Constant {
            static let title = "로그인이 필요해요"
            static let message = "로그인하면 학습 현황과 설정을 확인할 수 있어요."
        }

    }
}
