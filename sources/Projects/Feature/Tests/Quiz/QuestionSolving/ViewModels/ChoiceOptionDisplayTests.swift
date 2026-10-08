import DomainUseCaseInterface
import Testing

@testable import Feature

@Suite("ChoiceOptionDisplay 선택지 표시 상태")
struct ChoiceOptionDisplayTests {

    // MARK: Internal

    @Test
    func `편집 중에는 선택한 선택지만 강조하고 정답 여부를 표현하지 않는다`() {
        let options = ChoiceOptionDisplay.editing(
            choices: choices,
            selectedIndex: 2,
        )

        #expect(options.map(\.emphasis) == [.neutral, .neutral, .selected, .neutral])
    }

    @Test
    func `결과 표시는 서버가 알려준 정답 index만으로 판정한다`() {
        let grading = ChoiceGrading(
            isCorrect: false,
            correctIndex: 3,
            explanation: "",
        )
        let options = ChoiceOptionDisplay.answered(
            choices: choices,
            selectedIndex: 1,
            grading: grading,
        )

        #expect(options.map(\.emphasis) == [.neutral, .incorrect, .neutral, .correct])
    }

    @Test
    func `결과 상태에서 선택하지 않은 선택지는 중립으로 남는다`() {
        let grading = ChoiceGrading(
            isCorrect: true,
            correctIndex: 0,
            explanation: "",
        )
        let options = ChoiceOptionDisplay.answered(
            choices: choices,
            selectedIndex: 0,
            grading: grading,
        )

        #expect(options[1].emphasis == .neutral)
        #expect(options[2].emphasis == .neutral)
        #expect(options[3].emphasis == .neutral)
    }

    // MARK: Private

    private let choices = ["첫 번째", "두 번째", "세 번째", "네 번째"]

}
