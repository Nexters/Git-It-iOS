import SwiftUI
import UIComponent

extension ProfileScreen {
    struct LoadFailureView: View {

        // MARK: Internal

        let onRetry: () -> Void

        var body: some View {
            HStack {
                VStack(
                    alignment: .leading,
                    spacing: Constant.messageSpacing,
                ) {
                    StyledText(text: LocalizedText.Settings.profileLoadFailureTitle)
                        .textStyle(.subtitle3)
                    StyledText(text: LocalizedText.Settings.profileLoadFailureMessage)
                        .textStyle(.caption1)
                        .foregroundColorToken(.grey400)
                }
                Spacer()
                FeedbackActionButton(
                    title: LocalizedText.Settings.profileLoadFailureRetryButtonTitle,
                    action: onRetry,
                )
                .style(.secondary)
                .size(.small)
                .fixedSize(
                    horizontal: true,
                    vertical: false,
                )
            }
            .frame(minHeight: Constant.minHeight)
        }

        // MARK: Private

        private enum Constant {
            static let messageSpacing: CGFloat = 4
            static let minHeight: CGFloat = 88
        }

    }
}
