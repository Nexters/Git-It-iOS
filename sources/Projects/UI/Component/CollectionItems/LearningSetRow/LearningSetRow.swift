import DesignSystem
import SwiftUI

// MARK: - LearningSetRow

/// 프로젝트 상세의 학습 세트 목록 항목입니다.
///
/// 항목 본문은 정보 표시이고, 조작 단위는 우측의 시작 버튼 하나뿐입니다.
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
        HStack(alignment: .top, spacing: LayoutToken.compactSpacing.cgFloatValue) {
            VStack(alignment: .leading, spacing: LayoutToken.gutter.cgFloatValue) {
                StyledText.caption1(label, color: .blue100)

                StyledText.subtitle3(title)
                    .lineLimit(2)

                Spacer(minLength: 0)

                ProgressSegments(completed: clampedCompletedCount, total: questionCount)
            }
            .accessibilityElement(children: .combine)

            startButton
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
        .accessibilityElement(children: .contain)
    }

    // MARK: Internal

    static var height: CGFloat {
        Constant.height
    }

    static var minimumTouchArea: CGFloat {
        Constant.startTouchSize
    }

    static func clampedCompletedCount(completed: Int, total: Int) -> Int {
        min(max(completed, 0), max(total, 0))
    }

    // MARK: Private

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
                .designSystemForeground(.grey100)
                .frame(width: Constant.startSurfaceSize, height: Constant.startSurfaceSize)
                .background(Color(designSystem: .blue300), in: Circle())
                .frame(width: Constant.startTouchSize, height: Constant.startTouchSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) \(title) 학습 시작")
    }

}

#Preview("Learning Set Row") {
    VStack(spacing: LayoutToken.gutter.cgFloatValue) {
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
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
