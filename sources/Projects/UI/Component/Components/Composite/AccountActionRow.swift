import DesignSystem
import SwiftUI

// MARK: - AccountActionRow

public struct AccountActionRow: View {

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
            isDestructive: Bool = false,
        ) {
            self.title = title
            self.isDestructive = isDestructive
        }

        public let title: String
        public let isDestructive: Bool
    }

    public var body: some View {
        Button(action: onTap) {
            StyledText.body1(
                viewModel.title,
                color: viewModel.isDestructive ? .error : .grey100,
            )
            .frame(maxWidth: .infinity, minHeight: Constant.minimumHeight, alignment: .leading)
            .padding(.horizontal, Constant.horizontalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Private

    private enum Constant {
        static let horizontalPadding: CGFloat = 18
        static let minimumHeight: CGFloat = 44
    }

    private let viewModel: ViewModel
    private let onTap: () -> Void

}

#Preview("Account Action Row") {
    VStack(spacing: 0) {
        AccountActionRow(viewModel: .init(title: "로그아웃"))
        AccountActionRow(viewModel: .init(title: "회원 탈퇴", isDestructive: true))
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
