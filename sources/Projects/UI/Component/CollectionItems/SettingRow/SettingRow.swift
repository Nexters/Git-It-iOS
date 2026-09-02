import DesignSystem
import SwiftUI

// MARK: - SettingRow

/// 크기 결정 방식은 `SizingMode.fill`.
public struct SettingRow: View {

    // MARK: Lifecycle

    public init(
        title: String,
        value: String? = nil,
        showsDisclosure: Bool = true,
        onTap: @escaping () -> Void = { },
    ) {
        self.title = title
        self.value = value
        self.showsDisclosure = showsDisclosure
        self.onTap = onTap
    }

    // MARK: Public

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                StyledText.body1(title)

                Spacer(minLength: Constant.minimumTrailingSpacing)

                if let value {
                    StyledText.body2(value, color: .grey400)
                        .lineLimit(1)
                }

                if showsDisclosure {
                    Image(systemName: "chevron.right")
                        .designSystemForeground(.grey400)
                }
            }
            .padding(.horizontal, Constant.horizontalPadding)
            .frame(maxWidth: .infinity, minHeight: Constant.minimumHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressOverlay)
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    private let title: String
    private let value: String?
    private let showsDisclosure: Bool
    private let onTap: () -> Void

}

#Preview("Setting Row") {
    VStack(spacing: 0) {
        SettingRow(title: "닉네임 변경")
        SettingRow(title: "앱 버전", value: "1.0.0", showsDisclosure: false)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
