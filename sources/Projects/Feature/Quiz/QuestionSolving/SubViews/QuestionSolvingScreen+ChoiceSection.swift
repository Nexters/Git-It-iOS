import DesignSystem
import SwiftUI
import UIComponent

extension QuestionSolvingScreen {
    struct ChoiceSection: View {

        // MARK: Internal

        let options: [ChoiceOptionDisplay]
        let isEnabled: Bool
        let onSelect: (Int) -> Void

        var body: some View {
            VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                ForEach(options) { option in
                    ChoiceAnswerOption(
                        letter: Self.letter(forID: option.id),
                        text: option.text,
                        state: Self.optionState(emphasis: option.emphasis),
                        isExpanded: option.emphasis != .neutral,
                        onTap: { onSelect(option.id) },
                    )
                    .allowsHitTesting(isEnabled)
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

        static func letter(forID id: Int) -> String {
            guard id >= 0, id < Constant.letters.count else {
                return "\(id + 1)"
            }
            return Constant.letters[id]
        }

        // MARK: Private

        private enum Constant {
            static let letters = ["A", "B", "C", "D", "E", "F"]
        }

    }
}
