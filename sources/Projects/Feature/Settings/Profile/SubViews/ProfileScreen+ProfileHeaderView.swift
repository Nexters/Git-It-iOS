import SwiftUI
import UIComponent

extension ProfileScreen {
    struct ProfileHeaderView: View {

        // MARK: Internal

        let display: ProfileDisplay

        var body: some View {
            HStack(
                alignment: .top,
                spacing: Constant.avatarSpacing,
            ) {
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
                    spacing: Constant.infoSpacing,
                ) {
                    VStack(
                        alignment: .leading,
                        spacing: 0,
                    ) {
                        StyledText(text: display.name ?? "")
                            .textStyle(.subtitle2)
                        StyledText(text: display.email ?? "")
                            .textStyle(.caption1)
                            .foregroundColorToken(.grey400)
                    }

                    if display.hasBadges {
                        HStack(spacing: Constant.badgeSpacing) {
                            if let position = display.positionBadgeText {
                                TagBadge(text: position)
                                    .style(.accent)
                                    .size(.compact)
                            }
                            if let careerLevel = display.careerLevelBadgeText {
                                TagBadge(text: careerLevel)
                                    .size(.compact)
                            }
                        }
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading,
                )
            }
        }

        // MARK: Private

        private enum Constant {
            static let avatarSize: CGFloat = 78
            static let avatarSpacing: CGFloat = 15
            static let infoSpacing: CGFloat = 8
            static let badgeSpacing: CGFloat = 6
        }

    }
}
