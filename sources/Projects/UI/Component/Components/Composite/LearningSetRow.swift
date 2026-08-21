import DesignSystem
import SwiftUI

// MARK: - LearningSetRow

public struct LearningSetRow: View {

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
            questionCount: Int,
            progress: Double,
            isCompleted: Bool = false,
        ) {
            self.title = title
            self.questionCount = questionCount
            self.progress = progress
            self.isCompleted = isCompleted
        }

        public let title: String
        public let questionCount: Int
        public let progress: Double
        public let isCompleted: Bool
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: LayoutToken.gutter.cgFloatValue) {
                HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                    StyledText.subtitle3(viewModel.title)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    if viewModel.isCompleted {
                        TagBadge.accent("완료")
                    }
                }

                StyledText.caption1("문제 \(viewModel.questionCount)개", color: .grey400)

                Spacer(minLength: 0)

                ContinuousProgressBar(viewModel: .init(progress: viewModel.progress))
            }
            .padding(Constant.contentPadding)
            .frame(width: Constant.width, height: Constant.height, alignment: .topLeading)
            .designSystemBackground(.cardBackground)
            .designSystemCornerRadius(.large)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    // MARK: Internal

    static var width: CGFloat {
        Constant.width
    }

    static var height: CGFloat {
        Constant.height
    }

    // MARK: Private

    private enum Constant {
        static let width: CGFloat = 320
        static let height: CGFloat = 130
        static let contentPadding: CGFloat = 18
    }

    private let viewModel: ViewModel
    private let onTap: () -> Void

}

#Preview("Learning Set Row") {
    HStack(spacing: LayoutToken.gutter.cgFloatValue) {
        LearningSetRow(
            viewModel: .init(title: "Presentation 구조", questionCount: 12, progress: 0.4)
        )
        LearningSetRow(
            viewModel: .init(
                title: "State 관리",
                questionCount: 8,
                progress: 1,
                isCompleted: true,
            )
        )
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
