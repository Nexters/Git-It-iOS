import SwiftUI
import UIComponent

extension HomeScreen {
    struct ProfileHeaderView: View {
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
            } else {
                ScreenHeader(
                    style: .inlineUser,
                    user: display.name.map { .init(name: $0, role: display.role) },
                    leading: nil,
                ) {
                    ResourceImage(asset: .icon(.profile), contentMode: .fill)
                }
            }
        }

        private enum Constant {
            static let messageSpacing: CGFloat = 4
            static let failureMinHeight: CGFloat = 88
        }

    }
}
