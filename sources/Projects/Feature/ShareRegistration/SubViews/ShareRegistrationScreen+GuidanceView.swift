import DesignSystem
import SwiftUI
import UIComponent

extension ShareRegistrationScreen {

    struct GuidanceView: View {

        // MARK: Internal

        let title: String
        let message: String
        let retryTitle: String?
        let dismissTitle: String
        let onRetry: () -> Void
        let onDismiss: () -> Void

        var body: some View {
            VStack(spacing: LayoutToken.margin) {
                ScreenControlBar(onLeadingTap: onDismiss)
                    .designSystemScreenMargin()

                Spacer(minLength: 0)

                VStack(spacing: Constant.textSetSpacing) {
                    StyledText(text: title)
                        .textStyle(.subtitle1)
                        .multilineTextAlignment(.center)
                    StyledText(text: message)
                        .textStyle(.body2)
                        .foregroundColorToken(.grey400)
                        .multilineTextAlignment(.center)
                }
                .designSystemScreenMargin()
                .accessibilityElement(children: .combine)

                Spacer(minLength: 0)

                VStack(spacing: LayoutToken.compactSpacing) {
                    if let retryTitle {
                        FeedbackActionButton(
                            title: retryTitle,
                            action: onRetry,
                        )
                    }
                    FeedbackActionButton(
                        title: dismissTitle,
                        action: onDismiss,
                    )
                    .style(.secondary)
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
