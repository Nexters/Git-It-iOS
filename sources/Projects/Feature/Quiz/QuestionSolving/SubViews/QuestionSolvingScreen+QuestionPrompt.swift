import DesignSystem
import SwiftUI
import UIComponent

extension QuestionSolvingScreen {
    struct QuestionPrompt: View {

        let questionNumber: Int?
        let prompt: String

        var body: some View {
            VStack(alignment: .leading, spacing: LayoutToken.compactSpacing.cgFloatValue) {
                if let questionNumber {
                    TagBadge(text: "문제 \(questionNumber)", style: .accent)
                }

                StyledText.subtitle2(prompt)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }

    }
}
