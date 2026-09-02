import DesignSystem
import SwiftUI

// MARK: - QuestionPrompt

/// 크기 결정 방식은 `SizingMode.fill`.
public struct QuestionPrompt: View {

    // MARK: Lifecycle

    public init(
        index: Int,
        total: Int,
        prompt: String,
    ) {
        self.index = index
        self.total = total
        self.prompt = prompt
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: LayoutToken.compactSpacing.cgFloatValue) {
            StyledText.caption1("Q\(index) / \(total)", color: .blue100)
            StyledText.subtitle2(prompt)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    private let index: Int
    private let total: Int
    private let prompt: String

}

#Preview("Question Prompt") {
    QuestionPrompt(
        index: 3,
        total: 10,
        prompt: "SwiftUI에서 State와 Binding의 차이를 설명하세요.",
    )
    .frame(width: 320)
    .designSystemScreenMargin()
    .padding(.vertical, LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
