import DesignSystem
import SwiftUI
import UIComponent

extension QuestionSolvingScreen {
    struct EssayResultSection: View {

        let myAnswer: String
        let aiAnswer: String
        let criteria: [String]

        var body: some View {
            VStack(
                alignment: .leading,
                spacing: LayoutToken.margin,
            ) {
                LabeledCard(displayModel: .init(
                    label: LocalizedText.Quiz.essayResultSectionMyAnswerLabel,
                    text: myAnswer,
                ))
                LabeledCard(displayModel: .init(
                    label: LocalizedText.Quiz.essayResultSectionExplanationLabel,
                    text: aiAnswer,
                ))
                .style(.accent)
            }
        }

    }
}
