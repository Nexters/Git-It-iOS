import DesignSystem
import SwiftUI

// MARK: - PolicyAgreementRow

public struct PolicyAgreementRow: View {

    // MARK: Lifecycle

    public init(
        displayModel: DisplayModel,
        isSelected: Binding<Bool>,
        onOpenLink: @escaping () -> Void = { },
    ) {
        self.displayModel = displayModel
        _isSelected = isSelected
        self.onOpenLink = onOpenLink
    }

    // MARK: Public

    public var body: some View {
        HStack(spacing: LayoutToken.compactSpacing) {
            Button(action: { toggle() }) {
                HStack(spacing: LayoutToken.gutter) {
                    ResourceImage(asset: isSelected ? .icon(.statusCheck) : .icon(.statusDisabled))
                        .designSystemForeground(isSelected ? .blue100 : .grey400)
                        .frame(
                            width: Constant.checkSize,
                            height: Constant.checkSize,
                        )
                    StyledText(text: displayModel.title)
                        .textStyle(.body2)
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
                    .frame(
                        width: Constant.linkSurfaceSize,
                        height: Constant.linkSurfaceSize,
                    )
                    .frame(
                        width: Constant.minimumTouchSize,
                        height: Constant.minimumTouchSize,
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(openLinkAccessibilityLabel)
            .accessibilityIdentifier("policyAgreementRow.openLink.\(displayModel.title)")
        }
        .frame(height: 54)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: Internal

    static let minimumHitArea: CGFloat = 44

    func toggle() {
        isSelected.toggle()
    }

    // MARK: Private

    @Binding private var isSelected: Bool

    private let displayModel: DisplayModel
    private let onOpenLink: () -> Void

    private var accessibilityLabel: String {
        let requiredText = displayModel.isRequired
            ? LocalizedText.PolicyAgreementRow.requiredLabel
            : LocalizedText.PolicyAgreementRow.optionalLabel
        return "\(requiredText), \(displayModel.title)"
    }

    private var openLinkAccessibilityLabel: String {
        LocalizedText.PolicyAgreementRow.fullTextAccessibilityLabel(title: displayModel.title)
    }

}

// MARK: PolicyAgreementRow.Constant

extension PolicyAgreementRow {
    fileprivate enum Constant {
        static let checkSize: CGFloat = 24
        static let linkSurfaceSize: CGFloat = 36
        static let checkboxSpacing: CGFloat = 8
        static let minimumTouchSize: CGFloat = 44
    }
}

// MARK: PolicyAgreementRow.DisplayModel

extension PolicyAgreementRow {
    public struct DisplayModel: Sendable, Equatable {
        public init(
            title: String,
            isRequired: Bool,
        ) {
            self.title = title
            self.isRequired = isRequired
        }

        public let title: String
        public let isRequired: Bool
    }
}

#Preview("Policy Agreement Row") {
    VStack(spacing: LayoutToken.compactSpacing) {
        PolicyAgreementRow(
            displayModel: .init(
                title: "개인정보 처리방침",
                isRequired: true,
            ),
            isSelected: .constant(true),
        )
        PolicyAgreementRow(
            displayModel: .init(
                title: "서비스 이용 약관",
                isRequired: true,
            ),
            isSelected: .constant(false),
        )
        PolicyAgreementRow(
            displayModel: .init(
                title: "마케팅 정보 수신",
                isRequired: false,
            ),
            isSelected: .constant(false),
        )
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
