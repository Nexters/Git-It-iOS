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
        HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
            Button(action: onToggle) {
                HStack(spacing: LayoutToken.gutter.cgFloatValue) {
                    ResourceImage(asset: isSelected ? .icon(.checkmarkChecked) : .icon(.checkmarkDisable))
                        .designSystemForeground(isSelected ? .blue100 : .grey400)
                        .frame(width: Constant.checkSize, height: Constant.checkSize)
                    StyledText.body2(title)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            Spacer(minLength: 0)

            Button(action: onOpenLink) {
                Image(systemName: "chevron.right")
                    .designSystemForeground(.grey300)
                    .frame(width: Constant.linkSurfaceSize,
                           height: Constant.linkSurfaceSize)
                    .frame(width: Constant.minimumTouchSize,
                           height: Constant.minimumTouchSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(openLinkAccessibilityLabel)
            .accessibilityIdentifier("policyAgreementRow.openLink.\(title)")
        }
        .frame(height: 54)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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

    private var openLinkAccessibilityLabel: String {
        "\(title) 전문 보기"
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
