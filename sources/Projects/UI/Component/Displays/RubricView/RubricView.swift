import DesignSystem
import SwiftUI

// MARK: - RubricView

public struct RubricView: View {

    // MARK: Lifecycle

    public init(
        criteria: [String],
        overallFeedback: String? = nil,
    ) {
        self.criteria = criteria
        self.overallFeedback = overallFeedback
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: LayoutToken.gutter) {
            if let overallFeedback {
                StyledText.body1(overallFeedback)
            }

            VStack(alignment: .leading, spacing: LayoutToken.compactSpacing) {
                ForEach(Array(criteria.enumerated()), id: \.offset) { _, criterion in
                    HStack(alignment: .top, spacing: LayoutToken.compactSpacing) {
                        Image(systemName: "checkmark.circle")
                            .designSystemForeground(.blue100)
                        StyledText.body2(criterion, color: .grey300)
                    }
                }
            }
        }
        .padding(Constant.contentPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .designSystemBackground(.cardBackground)
        .designSystemCornerRadius(.large)
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    private let criteria: [String]
    private let overallFeedback: String?

}

// MARK: RubricView.Constant

extension RubricView {
    fileprivate enum Constant {
        static let contentPadding: CGFloat = 18
    }
}

#Preview("Rubric View") {
    RubricView(
        criteria: [
            "State와 Binding의 소유 관계를 정확히 설명했습니다",
            "실제 코드 예시를 함께 제시했습니다",
        ],
        overallFeedback: "핵심 개념을 잘 이해하고 있습니다.",
    )
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
