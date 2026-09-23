import SwiftUI
import UIComponent

extension HomeScreen {
    struct SignInSectionView: View {

        // MARK: Internal

        let onSignIn: () -> Void

        var body: some View {
            HStack {
                VStack(
                    alignment: .leading,
                    spacing: Constant.messageSpacing,
                ) {
                    StyledText(text: LocalizedText.Home.signInSectionTitle)
                        .textStyle(.subtitle3)
                    StyledText(text: LocalizedText.Home.signInSectionCaption)
                        .textStyle(.caption1)
                        .foregroundColorToken(.grey400)
                }
                Spacer()
                FeedbackActionButton(
                    title: LocalizedText.Home.signInSectionSignInButtonTitle,
                    action: onSignIn,
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
