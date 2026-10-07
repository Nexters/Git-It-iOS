import DesignSystem
import SwiftUI
import UIComponent

extension ProjectDetailScreen {
    struct MenuSheet: View {

        // MARK: Internal

        let onSavedQuestionsTap: () -> Void
        let onRepositoryLinkTap: () -> Void
        let onDeleteTap: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                menuRow(title: "저장한 문제", color: .grey100, action: onSavedQuestionsTap)
                menuRow(title: "GitHub에서 보기", color: .grey100, action: onRepositoryLinkTap)
                menuRow(title: "삭제하기", color: .error, action: onDeleteTap)
            }
            .padding(Constant.containerPadding)
            .frame(width: Constant.width, alignment: .leading)
            .glassEffect(
                .regular.tint(Color(designSystem: .white5)),
                in: RoundedRectangle(designSystem: .large),
            )
        }

        // MARK: Private

        private enum Constant {
            static let width: CGFloat = 160
            static let containerPadding: CGFloat = 4
            static let rowHorizontalPadding: CGFloat = 10
            static let rowTopPadding: CGFloat = 9
            static let rowBottomPadding: CGFloat = 10
        }

        private func menuRow(
            title: String,
            color: ColorToken,
            action: @escaping () -> Void,
        ) -> some View {
            Button(action: action) {
                StyledText.body2(title, color: color)
                    .padding(.horizontal, Constant.rowHorizontalPadding)
                    .padding(.top, Constant.rowTopPadding)
                    .padding(.bottom, Constant.rowBottomPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .designSystemCornerRadius(.large)
            .accessibilityLabel(title)
        }

    }
}
