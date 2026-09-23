import DomainQuizDetail
import Foundation

// MARK: - ChoiceOptionDisplay

public struct ChoiceOptionDisplay: Equatable, Sendable, Identifiable {

    // MARK: Lifecycle

    public init(
        id: Int,
        text: String,
        emphasis: Emphasis,
        isSelected: Bool,
    ) {
        self.id = id
        self.text = text
        self.emphasis = emphasis
        self.isSelected = isSelected
    }

    // MARK: Public

    public enum Emphasis: Equatable, Sendable {
        case neutral
        case selected
        case correct
        case incorrect
    }

    public let id: Int
    public let text: String
    public let emphasis: Emphasis
    public let isSelected: Bool

    public var accessibilityLabel: String {
        var parts = [LocalizedText.Quiz.choiceOptionNumberLabel(number: id + 1), text]
        if isSelected {
            parts.append(LocalizedText.Quiz.choiceOptionSelectedLabel)
        }
        switch emphasis {
        case .correct:
            parts.append(LocalizedText.Quiz.choiceOptionCorrectLabel)

        case .incorrect:
            parts.append(LocalizedText.Quiz.choiceOptionIncorrectLabel)

        case .neutral,
             .selected:
            break
        }
        return parts.joined(separator: ", ")
    }

    public static func editing(
        choices: [String],
        selectedIndex: Int?,
    ) -> [Self] {
        choices.enumerated().map { index, text in
            Self(
                id: index,
                text: text,
                emphasis: index == selectedIndex ? .selected : .neutral,
                isSelected: index == selectedIndex,
            )
        }
    }

    public static func answered(
        choices: [String],
        selectedIndex: Int?,
        grading: ChoiceGrading,
    ) -> [Self] {
        choices.enumerated().map { index, text in
            let isSelected = index == selectedIndex
            let emphasis: Emphasis =
                if index == grading.correctIndex {
                    .correct
                } else if isSelected {
                    .incorrect
                } else {
                    .neutral
                }
            return Self(
                id: index,
                text: text,
                emphasis: emphasis,
                isSelected: isSelected,
            )
        }
    }

}
