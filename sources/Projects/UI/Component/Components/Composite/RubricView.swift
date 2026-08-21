import DesignSystem
import SwiftUI

// MARK: - RubricView

public struct RubricView: View {

    // MARK: Lifecycle

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Public

    public struct ViewModel: Sendable, Equatable {
        public init(
            criteria: [String],
            overallFeedback: String? = nil,
        ) {
            self.criteria = criteria
            self.overallFeedback = overallFeedback
        }

        public let criteria: [String]
        public let overallFeedback: String?
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LayoutToken.gutter.cgFloatValue) {
            if let overallFeedback = viewModel.overallFeedback {
                StyledText.body1(overallFeedback)
            }

            VStack(alignment: .leading, spacing: LayoutToken.compactSpacing.cgFloatValue) {
                ForEach(Array(viewModel.criteria.enumerated()), id: \.offset) { _, criterion in
                    HStack(alignment: .top, spacing: LayoutToken.compactSpacing.cgFloatValue) {
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

    private enum Constant {
        static let contentPadding: CGFloat = 18
    }

    private let viewModel: ViewModel

}

#Preview("Rubric View") {
    RubricView(
        viewModel: .init(
            criteria: [
                "State와 Binding의 소유 관계를 정확히 설명했습니다",
                "실제 코드 예시를 함께 제시했습니다",
            ],
            overallFeedback: "핵심 개념을 잘 이해하고 있습니다.",
        )
    )
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
