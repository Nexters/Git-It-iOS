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
            SheetSurface {
                VStack(spacing: 0) {
                    menuRow(title: "저장한 문제", color: .grey100, action: onSavedQuestionsTap)
                    menuRow(title: "GitHub에서 보기", color: .grey100, action: onRepositoryLinkTap)
                    menuRow(title: "삭제하기", color: .error, action: onDeleteTap)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        // MARK: Private

        private enum Constant {
            static let rowHeight: CGFloat = 56
        }

        private func menuRow(
            title: String,
            color: ColorToken,
            action: @escaping () -> Void,
        ) -> some View {
            Button(action: action) {
                StyledText.body2(title, color: color)
                    .frame(maxWidth: .infinity, minHeight: Constant.rowHeight, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
        }

    }
}
