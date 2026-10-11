import DesignSystem
import SwiftUI

// MARK: - RubricView

public struct RubricView: View {

    // MARK: Lifecycle

    public init(displayModel: DisplayModel) {
        self.displayModel = displayModel
    }

    // MARK: Public

    public var body: some View {
        VStack(
            alignment: .leading,
            spacing: LayoutToken.gutter,
        ) {
            if let overallFeedback = displayModel.overallFeedback {
                StyledText(text: overallFeedback)
            }

            VStack(
                alignment: .leading,
                spacing: LayoutToken.compactSpacing,
            ) {
                ForEach(
                    Array(displayModel.criteria.enumerated()),
                    id: \.offset,
                ) { _, criterion in
                    HStack(
                        alignment: .top,
                        spacing: LayoutToken.compactSpacing,
                    ) {
                        Image(systemName: "checkmark.circle")
                            .designSystemForeground(.blue100)
                        StyledText(text: criterion)
                            .textStyle(.body2)
                            .foregroundColorToken(.grey300)
                    }
                }
            }
        }
        .padding(Constant.contentPadding)
        .frame(
            maxWidth: .infinity,
            alignment: .leading,
        )
        .designSystemBackground(.grey600)
        .designSystemCornerRadius(.large)
    }

    // MARK: Private

    private let displayModel: DisplayModel

}

// MARK: RubricView.DisplayModel

extension RubricView {
    public struct DisplayModel: Sendable, Equatable {
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
}

// MARK: RubricView.Constant

extension RubricView {
    fileprivate enum Constant {
        static let contentPadding: CGFloat = 18
    }
}

#Preview("Rubric View") {
    RubricView(
        displayModel: .init(
            criteria: [
                "State와 Binding의 소유 관계를 정확히 설명했습니다",
                "실제 코드 예시를 함께 제시했습니다",
            ],
            overallFeedback: "핵심 개념을 잘 이해하고 있습니다.",
        )
    )
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
