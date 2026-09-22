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
                    StyledText(text: Constant.title)
                        .textStyle(.subtitle3)
                    StyledText(text: Constant.caption)
                        .textStyle(.caption1)
                        .foregroundColorToken(.grey400)
                }
                Spacer()
                FeedbackActionButton(
                    title: Constant.signInTitle,
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
            static let title = "로그인이 필요해요"
            static let caption = "로그인하고 나만의 학습을 시작해 보세요."
            static let signInTitle = "로그인"
            static let messageSpacing: CGFloat = 4
            static let minHeight: CGFloat = 88
        }

    }
}
