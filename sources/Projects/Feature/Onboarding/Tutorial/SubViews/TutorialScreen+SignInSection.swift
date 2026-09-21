import DesignSystem
import SwiftUI
import UIComponent

extension TutorialScreen {
    struct SignInSection: View {

        // MARK: Internal

        let currentPage: Int
        let totalPages: Int
        let bundleVersion: String
        let isHintVisible: Bool
        let onAppleSignIn: () -> Void
        let onGuestAccess: () -> Void

        var body: some View {
            VStack {
                PageIndicator(currentPage: currentPage, totalPages: totalPages)
                    .padding(Constant.indicatorPadding)

                StyledText(text: Constant.hintTitle)
                    .textStyle(.caption1)
                    .foregroundColorToken(.grey400)
                    .multilineTextAlignment(.center)
                    .opacity(isHintVisible ? 1 : 0)
                    .accessibilityHidden(!isHintVisible)
                    .padding(.bottom, LayoutToken.compactSpacing)

                AppleSignInButton(action: onAppleSignIn)

                FeedbackActionButton(
                    title: Constant.guestAccessTitle,
                    style: .text,
                    size: .small,
                    isEnabled: isHintVisible,
                    action: onGuestAccess,
                )
                .opacity(isHintVisible ? 1 : 0)
                .accessibilityHidden(!isHintVisible)
                .padding(.top, LayoutToken.compactSpacing)

                StyledText(text: "버전 \(bundleVersion)")
                    .textStyle(.body2)
                    .foregroundColorToken(.grey500)
                    .multilineTextAlignment(.center)
                    .padding(.top, Constant.versionTopSpacing)
            }
            .designSystemScreenMargin()
            .padding(.bottom, Constant.bottomInset)
        }

        // MARK: Private

        private enum Constant {
            static let hintTitle = "3초만에 가입하기"
            static let guestAccessTitle = "로그인 없이 둘러보기"
            static let indicatorPadding: CGFloat = 12
            static let versionTopSpacing: CGFloat = 21
            static let bottomInset: CGFloat = 29
        }

    }
}
