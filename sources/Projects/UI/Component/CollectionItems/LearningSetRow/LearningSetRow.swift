import DesignSystem
import SwiftUI

// MARK: - LearningSetRow

public struct LearningSetRow: View {

    // MARK: Lifecycle

    public init(
        title: String,
        questionCount: Int,
        progress: Double,
        isCompleted: Bool = false,
        onTap: @escaping () -> Void = { },
    ) {
        self.title = title
        self.questionCount = questionCount
        self.progress = progress
        self.isCompleted = isCompleted
        self.onTap = onTap
    }

    // MARK: Public

    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: LayoutToken.gutter.cgFloatValue) {
                HStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                    StyledText.subtitle3(title)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    if isCompleted {
                        TagBadge.accent("완료")
                    }
                }

                StyledText.caption1("문제 \(questionCount)개", color: .grey400)

                Spacer(minLength: 0)

                ContinuousProgressBar(progress: progress)
            }
            .padding(Constant.contentPadding)
            .frame(maxWidth: .infinity, minHeight: Constant.height, alignment: .topLeading)
            .designSystemBackground(.screenBackground)
            .designSystemCornerRadius(.large)
            .overlay {
                RoundedRectangle(designSystem: .large)
                    .stroke(
                        Color(designSystem: BorderToken.default.colorToken),
                        lineWidth: CGFloat(BorderToken.default.width),
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    // MARK: Internal

    static var height: CGFloat {
        Constant.height
    }

    // MARK: Private

    private let title: String
    private let questionCount: Int
    private let progress: Double
    private let isCompleted: Bool
    private let onTap: () -> Void

}

#Preview("Learning Set Row") {
    HStack(spacing: LayoutToken.gutter.cgFloatValue) {
        LearningSetRow(title: "Presentation 구조", questionCount: 12, progress: 0.4)
        LearningSetRow(
            title: "State 관리",
            questionCount: 8,
            progress: 1,
            isCompleted: true,
        )
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
