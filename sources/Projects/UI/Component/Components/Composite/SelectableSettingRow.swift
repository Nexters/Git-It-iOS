import DesignSystem
import SwiftUI

// MARK: - SelectableSettingRow

public struct SelectableSettingRow: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        onTap: @escaping () -> Void = { },
    ) {
        self.viewModel = viewModel
        self.onTap = onTap
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init(
            title: String,
            isSelected: Bool = false,
        ) {
            self.title = title
            self.isSelected = isSelected
        }

        public let title: String
        public let isSelected: Bool
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                StyledText.body1(viewModel.title)

                Spacer(minLength: Constant.minimumTrailingSpacing)

                if viewModel.isSelected {
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
        .accessibilityAddTraits(viewModel.isSelected ? .isSelected : [])
    }

    // MARK: Private

    private enum Constant {
        static let horizontalPadding: CGFloat = 18
        static let minimumHeight: CGFloat = 52
        static let minimumTrailingSpacing: CGFloat = 4
    }

    private let viewModel: ViewModel
    private let onTap: () -> Void

}

#Preview("Selectable Setting Row") {
    VStack(spacing: 0) {
        SelectableSettingRow(viewModel: .init(title: "주니어", isSelected: true))
        SelectableSettingRow(viewModel: .init(title: "시니어"))
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
