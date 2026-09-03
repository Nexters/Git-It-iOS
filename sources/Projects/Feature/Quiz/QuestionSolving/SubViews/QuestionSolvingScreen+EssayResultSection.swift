import DesignSystem
import SwiftUI
import UIComponent

extension QuestionSolvingScreen {
    struct EssayResultSection: View {

        // MARK: Internal

        let myAnswer: String
        let aiAnswer: String
        let criteria: [String]

        var body: some View {
            VStack(alignment: .leading, spacing: LayoutToken.margin.cgFloatValue) {
                answerCard(title: "나의 답안", body: myAnswer)
                answerCard(title: "AI의 답안", body: aiAnswer)

                if !criteria.isEmpty {
                    RubricView(criteria: criteria)
                }
            }
        }

        // MARK: Private

        private enum Constant {
            static let cardPadding: CGFloat = 16
            static let titleSpacing: CGFloat = 8
        }

        private func answerCard(
            title: String,
            body: String,
        ) -> some View {
            VStack(alignment: .leading, spacing: Constant.titleSpacing) {
                StyledText.caption1(title, color: .blue100)
                StyledText.body2(body, color: .grey300)
            }
            .padding(Constant.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .designSystemBackground(.cardBackground)
            .designSystemCornerRadius(.large)
            .accessibilityElement(children: .combine)
        }

    }
}
