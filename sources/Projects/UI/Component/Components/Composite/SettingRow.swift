import DesignSystem
import SwiftUI

// MARK: - SettingRow

public struct SettingRow: View {

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
            value: String? = nil,
            showsDisclosure: Bool = true,
        ) {
            self.title = title
            self.value = value
            self.showsDisclosure = showsDisclosure
        }

        public let title: String
        public let value: String?
        public let showsDisclosure: Bool
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                StyledText.body1(viewModel.title)

                Spacer(minLength: Constant.minimumTrailingSpacing)

                if let value = viewModel.value {
                    StyledText.body2(value, color: .grey400)
                        .lineLimit(1)
                }

                if viewModel.showsDisclosure {
                    Image(systemName: "chevron.right")
                        .designSystemForeground(.grey400)
                }
            }
            .padding(.horizontal, Constant.horizontalPadding)
            .frame(maxWidth: .infinity, minHeight: Constant.minimumHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
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

#Preview("Setting Row") {
    VStack(spacing: 0) {
        SettingRow(viewModel: .init(title: "닉네임 변경"))
        SettingRow(viewModel: .init(title: "앱 버전", value: "1.0.0", showsDisclosure: false))
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
