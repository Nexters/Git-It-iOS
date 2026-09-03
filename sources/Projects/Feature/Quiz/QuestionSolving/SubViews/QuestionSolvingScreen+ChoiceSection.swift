import DesignSystem
import SwiftUI
import UIComponent

extension QuestionSolvingScreen {
    struct ChoiceSection: View {

        let options: [ChoiceOptionDisplay]
        let isEnabled: Bool
        let onSelect: (Int) -> Void

        var body: some View {
            VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                ForEach(options) { option in
                    ChoiceAnswerOption(
                        text: option.text,
                        state: Self.optionState(emphasis: option.emphasis),
                        onTap: { onSelect(option.id) },
                    )
                    .disabled(!isEnabled)
                    .accessibilityLabel(option.accessibilityLabel)
                }
            }
        }

        static func optionState(emphasis: ChoiceOptionDisplay.Emphasis) -> ChoiceAnswerOption.State {
            switch emphasis {
            case .neutral:
                .default

            case .selected:
                .selected

            case .correct:
                .correct

            case .incorrect:
                .incorrect
            }
        }

    }
}
