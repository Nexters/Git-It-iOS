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
                LabeledCard.neutral(label: "나의 답안", text: myAnswer)
                LabeledCard.neutral(label: "AI의 답안", text: aiAnswer)

                if !criteria.isEmpty {
                    RubricView(criteria: criteria)
                }
            }
        }

    }
}
