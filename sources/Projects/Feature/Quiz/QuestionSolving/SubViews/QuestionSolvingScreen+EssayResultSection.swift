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
            VStack(alignment: .leading, spacing: LayoutToken.margin) {
                LabeledCard(displayModel: .init(label: "나의 답안", text: myAnswer))
                LabeledCard(displayModel: .init(label: "AI 해설", text: aiAnswer))
                    .style(.accent)
            }
        }

    }
}
