import DesignSystem
import SwiftUI

// MARK: - SelectableSettingRow

public struct SelectableSettingRow: View {

    // MARK: Lifecycle

    public init(
        title: String,
        isSelected: Bool = false,
        onTap: @escaping () -> Void = { },
    ) {
        self.title = title
        self.isSelected = isSelected
        self.onTap = onTap
    }

    // MARK: Public

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                StyledText.body1(title)

                Spacer(minLength: Constant.minimumTrailingSpacing)

                if isSelected {
                    Image(systemName: "checkmark")
                        .designSystemForeground(.blue100)
                }
            }
            .padding(.horizontal, Constant.horizontalPadding)
            .frame(maxWidth: .infinity, minHeight: Constant.minimumHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: Private

    private let title: String
    private let isSelected: Bool
    private let onTap: () -> Void

}

#Preview("Selectable Setting Row") {
    VStack(spacing: 0) {
        SelectableSettingRow(title: "주니어", isSelected: true)
        SelectableSettingRow(title: "시니어")
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
