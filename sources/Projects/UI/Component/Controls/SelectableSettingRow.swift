import DesignSystem
import SwiftUI

// MARK: - SelectableSettingRow

public struct SelectableSettingRow: View {

    // MARK: Lifecycle

    public init(
        title: String,
        isSelected: Binding<Bool>,
    ) {
        self.title = title
        _isSelected = isSelected
    }

    // MARK: Public

    public var body: some View {
        Button(action: { toggle() }) {
            HStack(spacing: LayoutToken.compactSpacing) {
                StyledText(text: title)

                Spacer(minLength: Constant.minimumTrailingSpacing)

                if isSelected {
                    Image(systemName: "checkmark")
                        .designSystemForeground(.blue100)
                }
            }
            .padding(.horizontal, Constant.horizontalPadding)
            .frame(
                maxWidth: .infinity,
                minHeight: Constant.minimumHeight,
                alignment: .leading,
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: Internal

    func toggle() {
        isSelected.toggle()
    }

    // MARK: Private

    @Binding private var isSelected: Bool

    private let title: String

}

// MARK: SelectableSettingRow.Constant

extension SelectableSettingRow {
    fileprivate enum Constant {
        static let horizontalPadding: CGFloat = 18
        static let minimumHeight: CGFloat = 52
        static let minimumTrailingSpacing: CGFloat = 4
    }
}

#Preview("Selectable Setting Row") {
    VStack(spacing: 0) {
        SelectableSettingRow(
            title: "주니어",
            isSelected: .constant(true),
        )
        SelectableSettingRow(
            title: "시니어",
            isSelected: .constant(false),
        )
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
