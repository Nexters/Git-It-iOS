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
                PageIndicator(displayModel: .init(
                    currentPage: currentPage,
                    totalPages: totalPages,
                ))
                .padding(Constant.indicatorPadding)

                StyledText(text: LocalizedText.Onboarding.tutorialSignInHintTitle)
                    .textStyle(.caption1)
                    .foregroundColorToken(.grey400)
                    .multilineTextAlignment(.center)
                    .opacity(isHintVisible ? 1 : 0)
                    .accessibilityHidden(!isHintVisible)
                    .padding(.bottom, LayoutToken.compactSpacing)

                AppleSignInButton(action: onAppleSignIn)

                FeedbackActionButton(
                    title: LocalizedText.Onboarding.tutorialSignInGuestAccessButtonTitle,
                    action: onGuestAccess,
                )
                .enabled(isHintVisible)
                .style(.text)
                .size(.small)
                .opacity(isHintVisible ? 1 : 0)
                .accessibilityHidden(!isHintVisible)
                .padding(.top, LayoutToken.compactSpacing)

                StyledText(text: LocalizedText.Onboarding.tutorialSignInVersion(version: bundleVersion))
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
            static let indicatorPadding: CGFloat = 12
            static let versionTopSpacing: CGFloat = 21
            static let bottomInset: CGFloat = 29
        }

    }
}
