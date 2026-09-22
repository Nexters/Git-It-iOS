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
                    StyledText(text: Constant.title)
                        .textStyle(.subtitle3)
                    StyledText(text: Constant.message)
                        .textStyle(.caption1)
                        .foregroundColorToken(.grey400)
                }
                Spacer()
                FeedbackActionButton(
                    title: Constant.retryTitle,
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
            static let title = "프로필을 불러오지 못했어요"
            static let message = "잠시 후 다시 시도해 주세요."
            static let retryTitle = "다시 시도"
            static let messageSpacing: CGFloat = 4
            static let minHeight: CGFloat = 88
        }

    }
}
