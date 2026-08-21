import DesignSystem
import Testing

@testable import UIComponent

@Suite("ChoiceAnswerOption 계약")
struct ChoiceAnswerOptionTests {
    @Test
    func `correct 상태는 정답 토큰과 체크마크 심볼을 사용한다`() {
        let state = ChoiceAnswerOption.State.correct

        #expect(state.borderColor == .correct)
        #expect(state.symbol == "checkmark.circle.fill")
        #expect(state.accessibilitySuffix == "정답")
    }

    @Test
    func `incorrect 상태는 오답 토큰과 엑스 심볼을 사용한다`() {
        let state = ChoiceAnswerOption.State.incorrect

        #expect(state.borderColor == .incorrect)
        #expect(state.symbol == "xmark.circle.fill")
        #expect(state.accessibilitySuffix == "오답")
    }

    @Test
    func `default와 selected 상태는 접근성 접미사와 심볼이 없다`() {
        #expect(ChoiceAnswerOption.State.default.symbol == nil)
        #expect(ChoiceAnswerOption.State.default.accessibilitySuffix == nil)
        #expect(ChoiceAnswerOption.State.selected.symbol == nil)
        #expect(ChoiceAnswerOption.State.selected.accessibilitySuffix == nil)
    }

    @Test
    func `불변 ViewModel로 생성한다`() {
        let viewModel = ChoiceAnswerOption.ViewModel(text: "State", state: .selected)

        _ = ChoiceAnswerOption(viewModel: viewModel)
        #expect(viewModel.text == "State")
        #expect(viewModel.state == .selected)
    }
}
