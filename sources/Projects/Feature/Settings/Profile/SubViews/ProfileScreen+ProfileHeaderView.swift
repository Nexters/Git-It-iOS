import SwiftUI
import UIComponent

extension ProfileScreen {
    /// 아바타·이름·이메일·직군/연차 배지(Figma `1539:19210` Profile Card).
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
                        StyledText.subtitle2(display.name ?? "")
                        StyledText.caption1(display.email ?? "", color: .grey400)
                    }

                    if display.hasBadges {
                        HStack(spacing: Constant.badgeSpacing) {
                            if let position = display.positionBadgeText {
                                TagBadge.accent(position)
                            }
                            if let careerLevel = display.careerLevelBadgeText {
                                TagBadge.neutral(careerLevel)
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
