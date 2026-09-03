import DesignSystem
import Testing

@testable import UIComponent

@Suite("ChoiceAnswerOption 계약")
struct ChoiceAnswerOptionTests {
    @Test
    func `correct 상태는 정답 토큰과 흰색 레터를 사용한다`() {
        let state = ChoiceAnswerOption.State.correct

        #expect(state.fillToken == .correct)
        #expect(state.letterColor == .grey100)
        #expect(state.accessibilitySuffix == "정답")
    }

    @Test
    func `incorrect 상태는 오답 토큰과 흰색 레터를 사용한다`() {
        let state = ChoiceAnswerOption.State.incorrect

        #expect(state.fillToken == .incorrect)
        #expect(state.letterColor == .grey100)
        #expect(state.accessibilitySuffix == "오답")
    }

    @Test
    func `default 상태는 채움색이 없고 접근성 접미사가 없다`() {
        #expect(ChoiceAnswerOption.State.default.fillToken == nil)
        #expect(ChoiceAnswerOption.State.default.letterColor == .blue200)
        #expect(ChoiceAnswerOption.State.default.accessibilitySuffix == nil)
    }

    @Test
    func `selected 상태는 정답과 동일한 채움색을 쓰고 접근성 접미사가 없다`() {
        #expect(ChoiceAnswerOption.State.selected.fillToken == .correct)
        #expect(ChoiceAnswerOption.State.selected.accessibilitySuffix == nil)
    }

    @Test
    func `표시 값을 직접 받아 생성한다`() {
        _ = ChoiceAnswerOption(letter: "A", text: "State", state: .selected)
    }
}
