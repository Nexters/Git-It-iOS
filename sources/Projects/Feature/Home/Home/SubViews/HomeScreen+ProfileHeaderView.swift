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
                    VStack(alignment: .leading, spacing: Constant.messageSpacing) {
                        StyledText.subtitle3("프로필을 불러오지 못했어요")
                        StyledText.caption1("잠시 후 다시 시도해 주세요.", color: .grey400)
                    }
                    Spacer()
                    ActionButton.secondary("다시 시도", size: .small, action: onRetry)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(minHeight: Constant.failureMinHeight)
            } else if let name = display.name {
                HStack(spacing: Constant.userProfileSpacing) {
                    ResourceImage(asset: .icon(.profile), contentMode: .fill)
                        .frame(width: Constant.avatarSize, height: Constant.avatarSize)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 0) {
                        StyledText.subtitle3(name)
                        StyledText.body3(display.role, color: .grey400)
                    }
                }
                .accessibilityElement(children: .combine)
                .padding(.top, Constant.topPadding)
                .padding(.bottom, Constant.bottomPadding)
                .frame(height: Constant.headerHeight, alignment: .top)
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
