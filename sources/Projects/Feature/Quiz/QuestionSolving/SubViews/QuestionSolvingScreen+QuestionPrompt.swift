import DesignSystem
import SwiftUI
import UIComponent

extension QuestionSolvingScreen {
    struct QuestionPrompt: View {

        // MARK: Internal

        let questionNumber: Int?
        let prompt: String

        var body: some View {
            VStack(
                alignment: .leading,
                spacing: Constant.contentSpacing,
            ) {
                if let questionNumber {
                    TagBadge(text: LocalizedText.Quiz.QuestionPrompt.Number.badge(questionNumber: questionNumber))
                        .style(.accent)
                }

                StyledText(text: prompt)
                    .textStyle(.subtitle3)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading,
            )
        }

        // MARK: Private

        private enum Constant {
            static let contentSpacing: CGFloat = 10
        }

    }
}
