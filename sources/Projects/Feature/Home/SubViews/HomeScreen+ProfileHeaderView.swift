import SwiftUI
import UIComponent

extension HomeScreen {
    struct ProfileHeaderView: View {

        // MARK: Internal

        let display: HomeProfileDisplay
        let onRetry: () -> Void

        var body: some View {
            if display.isFailed {
                HStack {
                    VStack(
                        alignment: .leading,
                        spacing: Constant.messageSpacing,
                    ) {
                        StyledText(text: LocalizedText.Home.ProfileHeader.LoadFailure.title)
                            .textStyle(.subtitle3)
                        StyledText(text: LocalizedText.Home.ProfileHeader.LoadFailure.message)
                            .textStyle(.caption1)
                            .foregroundColorToken(.grey400)
                    }
                    Spacer()
                    FeedbackActionButton(
                        title: LocalizedText.Home.ProfileHeader.Retry.buttonTitle,
                        action: onRetry,
                    )
                    .style(.secondary)
                    .size(.small)
                    .fixedSize(
                        horizontal: true,
                        vertical: false,
                    )
                }
                .frame(minHeight: Constant.failureMinHeight)
            } else if let name = display.name {
                HStack(spacing: Constant.userProfileSpacing) {
                    ResourceImage(
                        asset: .icon(.profile),
                        contentMode: .fill,
                    )
                    .frame(
                        width: Constant.avatarSize,
                        height: Constant.avatarSize,
                    )
                    .clipShape(Circle())

                    VStack(
                        alignment: .leading,
                        spacing: 0,
                    ) {
                        StyledText(text: name)
                            .textStyle(.subtitle3)
                        StyledText(text: display.role)
                            .textStyle(.body3)
                            .foregroundColorToken(.grey400)
                    }
                }
                .padding(.top, Constant.topPadding)
                .padding(.bottom, Constant.bottomPadding)
                .frame(
                    height: Constant.headerHeight,
                    alignment: .top,
                )
            } else {
                Color.clear
                    .frame(height: Constant.headerHeight)
            }
        }

        // MARK: Private

        private enum Constant {
            static let messageSpacing: CGFloat = 4
            static let failureMinHeight: CGFloat = 88
            static let headerHeight: CGFloat = 74
            static let topPadding: CGFloat = 20
            static let bottomPadding: CGFloat = 10
            static let userProfileSpacing: CGFloat = 11
            static let avatarSize: CGFloat = 40
        }

    }
}
