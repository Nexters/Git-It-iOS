import DesignSystem
import SwiftUI
import UIComponent

extension QuestionSolvingScreen {
    struct QuestionPrompt: View {

        // MARK: Internal

        let questionNumber: Int?
        let questionCount: Int?
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

        // MARK: Private

        private var orderText: String? {
            guard let questionNumber else { return nil }
            guard let questionCount else { return "Q\(questionNumber)" }
            return "Q\(questionNumber) / \(questionCount)"
        }

    }
}
