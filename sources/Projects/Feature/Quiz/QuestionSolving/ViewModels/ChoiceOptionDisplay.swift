import DomainLearningProject
import Foundation

// MARK: - ChoiceOptionDisplay

/// 선택지 하나의 표시 값입니다. 강조 상태는 서버 채점 결과에서만 파생합니다.
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

    /// 색 이외의 구별 수단으로 순번·선택 여부·채점 결과를 문장에 담습니다.
    public var accessibilityLabel: String {
        var parts = ["\(id + 1)번 선택지", text]
        if isSelected {
            parts.append("선택함")
        }
        switch emphasis {
        case .correct:
            parts.append("정답")

        case .incorrect:
            parts.append("오답")

        case .neutral,
             .selected:
            break
        }
        return parts.joined(separator: ", ")
    }

    /// 편집 중인 선택지 목록입니다. 채점 결과가 없으므로 정답 여부를 표현하지 않습니다.
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

    /// 채점 결과가 있는 선택지 목록입니다. `result`의 값만으로 강조를 판정합니다.
    public static func answered(
        choices: [String],
        selectedIndex: Int?,
        result: ChoiceAnswerResult,
    ) -> [Self] {
        choices.enumerated().map { index, text in
            let isSelected = index == selectedIndex
            let emphasis: Emphasis =
                if index == result.answerIndex {
                    .correct
                } else if isSelected {
                    .incorrect
                } else {
                    .neutral
                }
            return Self(id: index, text: text, emphasis: emphasis, isSelected: isSelected)
        }
    }

}
