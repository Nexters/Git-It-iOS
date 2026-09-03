import DesignSystem
import SwiftUI
import UIComponent

extension QuestionSolvingScreen {
    struct ChoiceSection: View {

        // MARK: Internal

        let questionID: String
        let options: [ChoiceOptionDisplay]
        let isEnabled: Bool
        /// 서버 채점 결과가 도착했는지 여부입니다. 채점 전에는 선택 여부만으로 펼침이
        /// 결정되는 `fixed` 형태를, 채점 후에는 독립적으로 열고 닫을 수 있는
        /// `toggleable` 형태를 사용합니다.
        let isGraded: Bool
        let onSelect: (Int) -> Void

        @State private var expandedOptionIDs: Set<Int> = []

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

        /// 채점 전에는 선택 여부와 무관하게 모든 선택지를 항상 펼쳐 보여주고,
        /// 채점 후에는 `expandedOptionIDs`로 독립적인 펼침 상태를 관리합니다.
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

        /// 채점 결과로 강조된 선택지(정답·오답 선택)는 처음 진입할 때 펼쳐 보여줍니다.
        /// 이후 각 선택지는 `toggleExpansion`으로 독립적으로 열고 닫을 수 있습니다.
        private func syncEmphasizedExpansion() {
            guard isGraded else { return }
            for option in options where option.emphasis != .neutral {
                expandedOptionIDs.insert(option.id)
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
