import DesignSystem
import SwiftUI
import UIComponent

extension QuestionSolvingScreen {
    struct QuestionPrompt: View {

        // MARK: Internal

        let questionNumber: Int?
        let prompt: String

        var body: some View {
            VStack(alignment: .leading, spacing: Constant.contentSpacing) {
                if let questionNumber {
                    TagBadge(text: "문제 \(questionNumber)", style: .accent)
                }

                StyledText.subtitle3(prompt)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }

        // MARK: Private

        private enum Constant {
            static let contentSpacing: CGFloat = 10
        }

    }
}
