import DesignSystem
import SwiftUI

// MARK: - PolicyAgreementRow

public struct PolicyAgreementRow: View {

    // MARK: Lifecycle

    public init(
        title: String,
        isRequired: Bool,
        isSelected: Bool = false,
        onToggle: @escaping () -> Void = { },
        onOpenLink: @escaping () -> Void = { },
    ) {
        self.title = title
        self.isRequired = isRequired
        self.isSelected = isSelected
        self.onToggle = onToggle
        self.onOpenLink = onOpenLink
    }

    // MARK: Public

    public var body: some View {
        Button(action: onToggle) {
            HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                HStack(spacing: 12) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .designSystemForeground(isSelected ? .blue100 : .grey400)
                    StyledText.body1(title)
                }

                Spacer(minLength: 0)

                Button(action: onOpenLink) {
                    Image(systemName: "chevron.right")
                        .designSystemForeground(.grey300)
                        .frame(width: Constant.minimumTouchSize,
                               height: Constant.minimumTouchSize)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain)
            }.buttonStyle(.plain)
        }
        .frame(height: 54)
    }

    // MARK: Internal

    static let minimumHitArea: CGFloat = 44

    // MARK: Private

    private let title: String
    private let isRequired: Bool
    private let isSelected: Bool
    private let onToggle: () -> Void
    private let onOpenLink: () -> Void

    private var accessibilityLabel: String {
        let requiredText = isRequired ? "필수" : "선택"
        return "\(requiredText), \(title)"
    }

}

#Preview("Policy Agreement Row") {
    VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
        PolicyAgreementRow(title: "개인정보 처리방침", isRequired: true, isSelected: true)
        PolicyAgreementRow(title: "서비스 이용 약관", isRequired: true)
        PolicyAgreementRow(title: "마케팅 정보 수신", isRequired: false)
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
