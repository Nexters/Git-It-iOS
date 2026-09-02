import DesignSystem
import SwiftUI
import UIComponent

// MARK: - QuestionPrompt

/// 문제 번호와 지문을 함께 읽히게 묶는 Sub View.
///
/// 화면이 소유하는 값을 그대로 받아 표시만 한다. 크기 결정 방식은 채움이다.
struct QuestionPrompt: View {

    // MARK: Internal

    let index: Int
    let total: Int
    let prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutToken.compactSpacing.cgFloatValue) {
            StyledText.caption1("Q\(index) / \(total)", color: .blue100)
            StyledText.subtitle2(prompt)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

}

#Preview("Question Prompt") {
    QuestionPrompt(
        index: 3,
        total: 10,
        prompt: "SwiftUI에서 State와 Binding의 차이를 설명하세요.",
    )
    .padding(LayoutToken.margin.cgFloatValue)
    .designSystemBackground(.grey700)
}
