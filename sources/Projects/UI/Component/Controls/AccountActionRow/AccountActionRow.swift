import DesignSystem
import SwiftUI

// MARK: - AccountActionRow

public struct AccountActionRow: View {

    // MARK: Lifecycle

    public init(
        title: String,
        isDestructive: Bool = false,
        onTap: @escaping () -> Void = { },
    ) {
        self.title = title
        self.isDestructive = isDestructive
        self.onTap = onTap
    }

    // MARK: Public

    public var body: some View {
        Button(action: onTap) {
            StyledText.body1(
                title,
                color: isDestructive ? .error : .grey100,
            )
            .frame(maxWidth: .infinity, minHeight: Constant.minimumHeight, alignment: .leading)
            .padding(.horizontal, Constant.horizontalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Private

    private let title: String
    private let isDestructive: Bool
    private let onTap: () -> Void

}

#Preview("Account Action Row") {
    VStack(spacing: 0) {
        AccountActionRow(title: "로그아웃")
        AccountActionRow(title: "회원 탈퇴", isDestructive: true)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
