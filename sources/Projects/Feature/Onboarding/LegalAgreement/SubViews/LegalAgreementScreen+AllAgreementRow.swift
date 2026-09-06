import DesignSystem
import SwiftUI
import UIComponent

extension LegalAgreementScreen {
    struct AllAgreementRow: View {

        // MARK: Internal

        let isSelected: Bool
        let onToggle: () -> Void

        var body: some View {
            Button(action: onToggle) {
                HStack(spacing: Constant.checkSpacing) {
                    ResourceImage(asset: isSelected ? .icon(.checkmarkChecked) : .icon(.checkmarkDisable))
                        .designSystemForeground(isSelected ? .blue100 : .grey400)
                        .frame(width: Constant.checkSize, height: Constant.checkSize)
                    StyledText.body2(Constant.title)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Constant.rowHorizontalPadding)
                .frame(height: Constant.rowHeight)
                .frame(maxWidth: .infinity)
                .designSystemBackground(.raisedBackground)
                .designSystemCornerRadius(.medium)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }

        // MARK: Private

        private enum Constant {
            static let title = "전체 동의"
            static let rowHeight: CGFloat = 54
            static let checkSize: CGFloat = 24
            static let checkSpacing: CGFloat = 12
            static let rowHorizontalPadding: CGFloat = 17
        }

    }
}
