import DesignSystem
import SwiftUI
import UIComponent

extension QuestionSolvingScreen {
    struct ChoiceSection: View {

        // MARK: Internal

        let questionID: String
        let options: [ChoiceOptionDisplay]
        let isEnabled: Bool
        let isGraded: Bool
        let onSelect: (Int) -> Void

        var body: some View {
            VStack(spacing: LayoutToken.compactSpacing.cgFloatValue) {
                ForEach(options) { option in
                    ChoiceAnswerOption(
                        letter: Self.letter(forID: option.id),
                        text: option.text,
                        state: Self.optionState(emphasis: option.emphasis),
                        expansion: expansion(for: option),
                        onTap: { onSelect(option.id) },
                    )
                    .allowsHitTesting(isGraded || isEnabled)
                    .accessibilityLabel(option.accessibilityLabel)
                }
            }
            .onAppear(perform: syncEmphasizedExpansion)
            .onChange(of: questionID) { _, _ in expandedOptionIDs = [] }
            .onChange(of: options) { _, _ in syncEmphasizedExpansion() }
        }

        // MARK: Private

        private enum Constant {
            static let letters = ["A", "B", "C", "D", "E", "F"]
        }

        @State private var expandedOptionIDs = Set<Int>()

        private static func optionState(emphasis: ChoiceOptionDisplay.Emphasis) -> ChoiceAnswerOption.State {
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

        private static func letter(forID id: Int) -> String {
            guard id >= 0, id < Constant.letters.count else {
                return "\(id + 1)"
            }
            return Constant.letters[id]
        }

        private func expansion(for option: ChoiceOptionDisplay) -> ChoiceAnswerOption.ExpansionControl {
            guard isGraded else {
                return .fixed(isExpanded: true)
            }
            return .toggleable(
                isExpanded: expandedOptionIDs.contains(option.id),
                onToggleExpand: { toggleExpansion(option.id) },
            )
        }

        private func toggleExpansion(_ id: Int) {
            if expandedOptionIDs.contains(id) {
                expandedOptionIDs.remove(id)
            } else {
                expandedOptionIDs.insert(id)
            }
        }

        private func syncEmphasizedExpansion() {
            guard isGraded else { return }
            for option in options where option.emphasis != .neutral {
                expandedOptionIDs.insert(option.id)
            }
        }

    }
}
