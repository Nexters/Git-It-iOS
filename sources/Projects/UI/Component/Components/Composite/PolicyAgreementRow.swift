import DesignSystem
import SwiftUI

// MARK: - PolicyAgreementRow

/// 정책 문서 한 건의 필수 표시, 선택, 외부 브라우저 열기 action을 나타내는 공용 표현입니다.
/// 브라우저 page load 상태는 이 컴포넌트가 추적하지 않고, 열기 요청 자체의 실패 여부만
/// `openLinkFailed`로 전달받아 retry 진입점을 노출합니다.
public struct PolicyAgreementRow: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        onToggle: @escaping () -> Void = { },
        onOpenLink: @escaping () -> Void = { },
        onRetryOpenLink: @escaping () -> Void = { },
    ) {
        self.viewModel = viewModel
        self.onToggle = onToggle
        self.onOpenLink = onOpenLink
        self.onRetryOpenLink = onRetryOpenLink
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init(
            title: String,
            isRequired: Bool,
            isSelected: Bool = false,
            openLinkFailed: Bool = false,
        ) {
            self.title = title
            self.isRequired = isRequired
            self.isSelected = isSelected
            self.openLinkFailed = openLinkFailed
        }

        public let title: String
        public let isRequired: Bool
        public let isSelected: Bool
        public let openLinkFailed: Bool
    }

    public var body: some View {
        HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
            Button(action: onToggle) {
                HStack(spacing: Constant.checkboxSpacing) {
                    Image(systemName: viewModel.isSelected ? "checkmark.square.fill" : "square")
                        .designSystemForeground(viewModel.isSelected ? .blue100 : .grey400)

                    requiredBadge

                    StyledText.body1(viewModel.title)
                }
                .frame(minHeight: Constant.minimumTouchSize, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(viewModel.isSelected ? .isSelected : [])

            Spacer(minLength: 0)

            if viewModel.openLinkFailed {
                Button(action: onRetryOpenLink) {
                    Image(systemName: "arrow.clockwise")
                        .designSystemForeground(.grey300)
                        .frame(width: Constant.minimumTouchSize, height: Constant.minimumTouchSize)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(viewModel.title) 열기 실패, 다시 시도")
            } else {
                Button(action: onOpenLink) {
                    Image(systemName: "chevron.right")
                        .designSystemForeground(.grey300)
                        .frame(width: Constant.minimumTouchSize, height: Constant.minimumTouchSize)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(viewModel.title) 보기")
            }
        }
    }

    // MARK: Internal

    static let minimumHitArea: CGFloat = 44

    // MARK: Private

    private enum Constant {
        static let checkboxSpacing: CGFloat = 8
        static let minimumTouchSize: CGFloat = 44
    }

    private let viewModel: ViewModel
    private let onToggle: () -> Void
    private let onOpenLink: () -> Void
    private let onRetryOpenLink: () -> Void

    private var accessibilityLabel: String {
        let requiredText = viewModel.isRequired ? "필수" : "선택"
        return "\(requiredText), \(viewModel.title)"
    }

    private var requiredBadge: some View {
        viewModel.isRequired ? TagBadge.accent("필수") : TagBadge.neutral("선택")
    }

}

#Preview("Policy Agreement Row") {
    VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
        PolicyAgreementRow(viewModel: .init(title: "개인정보 처리방침", isRequired: true, isSelected: true))
        PolicyAgreementRow(viewModel: .init(title: "서비스 이용 약관", isRequired: true))
        PolicyAgreementRow(viewModel: .init(title: "마케팅 정보 수신", isRequired: false))
        PolicyAgreementRow(viewModel: .init(title: "서비스 이용 약관", isRequired: true, openLinkFailed: true))
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
