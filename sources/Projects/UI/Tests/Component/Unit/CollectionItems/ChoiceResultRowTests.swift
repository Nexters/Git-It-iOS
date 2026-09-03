import DesignSystem
import Testing

@testable import UIComponent

@Suite("ChoiceResultRow 계약")
struct ChoiceResultRowTests {
    @Test
    func `판정과 펼침 여부를 모두 값으로 받는다`() {
        _ = ChoiceResultRow(
            judgement: .correct,
            isExpanded: false,
            text: "본문",
            explanation: "해설",
        ) { }
        _ = ChoiceResultRow(
            judgement: .incorrect,
            isExpanded: true,
            text: "본문",
            explanation: "해설",
        ) { }
    }

    @Test
    func `펼침 여부를 스스로 보관하지 않는다`() {
        let row = ChoiceResultRow(
            judgement: .correct,
            isExpanded: false,
            text: "본문",
            explanation: "해설",
        ) { }
        let stateProperties = Mirror(reflecting: row).children.filter {
            ($0.label ?? "").hasPrefix("_")
        }

        #expect(stateProperties.isEmpty)
    }

    @Test
    func `접근성 라벨에 판정을 접미로 붙인다`() {
        #expect(
            ChoiceResultRow.accessibilityLabel(text: "본문", judgement: .correct) == "본문, 정답"
        )
        #expect(
            ChoiceResultRow.accessibilityLabel(text: "본문", judgement: .incorrect) == "본문, 오답"
        )
    }

    @Test
    func `판정별 배경은 색 토큰을 참조한다`() {
        #expect(ChoiceResultRow.Judgement.correct.backgroundColor == ColorToken.correct)
        #expect(ChoiceResultRow.Judgement.incorrect.backgroundColor == ColorToken.incorrect)
    }
}
