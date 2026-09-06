import DesignSystem
import SwiftUI

// MARK: - LearningSetRow

public struct LearningSetRow: View {

    // MARK: Lifecycle

    public init(
        label: String,
        title: String,
        questionCount: Int,
        completedCount: Int,
        onStart: @escaping () -> Void = { },
    ) {
        self.label = label
        self.title = title
        self.questionCount = questionCount
        self.completedCount = completedCount
        self.onStart = onStart
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: Constant.contentSpacing) {
            HStack(alignment: .top, spacing: LayoutToken.gutter) {
                VStack(alignment: .leading, spacing: Constant.titleSpacing) {
                    StyledText.subtitle3(label, color: .blue100)

                    StyledText.body1(title)
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)

                startButton
            }

            ProgressSegments(completed: clampedCompletedCount, total: questionCount)
        }
        .padding(.horizontal, Constant.horizontalPadding)
        .padding(.vertical, Constant.verticalPadding)
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
        .accessibilityElement(children: .contain)
    }

    // MARK: Internal

    static var height: CGFloat {
        Constant.height
    }

    static var minimumTouchArea: CGFloat {
        Constant.startTouchSize
    }

    static func clampedCompletedCount(
        completed: Int,
        total: Int,
    ) -> Int {
        min(max(completed, 0), max(total, 0))
    }

    // MARK: Private

    private enum Constant {
        static let height: CGFloat = 130
        static let horizontalPadding: CGFloat = 18
        static let verticalPadding: CGFloat = 20
        static let contentSpacing: CGFloat = 25
        static let titleSpacing: CGFloat = 10
        static let startSymbolSize: CGFloat = 12
        static let startSurfaceSize: CGFloat = 32
        static let startTouchSize: CGFloat = 44
    }

    private let label: String
    private let title: String
    private let questionCount: Int
    private let completedCount: Int
    private let onStart: () -> Void

    private var clampedCompletedCount: Int {
        Self.clampedCompletedCount(completed: completedCount, total: questionCount)
    }

    private var startButton: some View {
        Button(action: onStart) {
            Image(systemName: "play.fill")
                .font(.system(size: Constant.startSymbolSize, weight: .bold))
                .designSystemForeground(.blue100)
                .frame(width: Constant.startSurfaceSize, height: Constant.startSurfaceSize)
                .background(Color(designSystem: .blue400), in: Circle())
                .frame(width: Constant.startTouchSize, height: Constant.startTouchSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) \(title) 학습 시작")
    }

}

#Preview("Learning Set Row") {
    VStack(spacing: LayoutToken.gutter) {
        LearningSetRow(
            label: "Set 1",
            title: "아이디어 PT 핵심 내용 확인하기",
            questionCount: 7,
            completedCount: 0,
        )
        LearningSetRow(
            label: "Set 2",
            title: "서비스 문제와 타깃 알아보기",
            questionCount: 2,
            completedCount: 2,
        )
    }
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin)
    .designSystemBackground(.grey700)
}
