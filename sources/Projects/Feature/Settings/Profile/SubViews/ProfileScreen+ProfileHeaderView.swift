import SwiftUI
import UIComponent

extension ProfileScreen {
    struct ProfileHeaderView: View {

        // MARK: Internal

        let display: ProfileDisplay

        var body: some View {
            HStack(alignment: .top, spacing: Constant.avatarSpacing) {
                ResourceImage(asset: .icon(.profile), contentMode: .fill)
                    .frame(width: Constant.avatarSize, height: Constant.avatarSize)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Constant.infoSpacing) {
                    VStack(alignment: .leading, spacing: 0) {
                        StyledText(text: display.name ?? "", style: .subtitle2)
                        StyledText(text: display.email ?? "", style: .caption1, color: .grey400)
                    }

                    if display.hasBadges {
                        HStack(spacing: Constant.badgeSpacing) {
                            if let position = display.positionBadgeText {
                                TagBadge(text: position, style: .accent, size: .compact)
                            }
                            if let careerLevel = display.careerLevelBadgeText {
                                TagBadge(text: careerLevel, style: .neutral, size: .compact)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
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
