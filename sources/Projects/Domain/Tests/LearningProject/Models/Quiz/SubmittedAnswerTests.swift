import Testing

@testable import DomainLearningProject

@Suite("SubmittedAnswer")
struct SubmittedAnswerTests {

    @Test
    func `객관식 답변은 선택 index와 정답 여부를 함께 보존한다`() {
        let answer = SubmittedAnswer(selectedIndex: 2, text: nil, correct: true)

        #expect(answer.selectedIndex == 2)
        #expect(answer.text == nil)
        #expect(answer.correct == true)
    }

    @Test
    func `오답으로 채점된 객관식 답변은 정답 여부를 거짓으로 보존한다`() {
        let answer = SubmittedAnswer(selectedIndex: 0, text: nil, correct: false)

        #expect(answer.selectedIndex == 0)
        #expect(answer.correct == false)
    }

    @Test
    func `서술형 답변은 작성 텍스트를 보존하고 정답 여부를 갖지 않는다`() {
        let answer = SubmittedAnswer(selectedIndex: nil, text: "작성한 답안", correct: nil)

        #expect(answer.selectedIndex == nil)
        #expect(answer.text == "작성한 답안")
        #expect(answer.correct == nil)
    }

    @Test
    func `선택 index와 작성 텍스트를 서로 다른 값으로 구분해 보존한다`() {
        let choice = SubmittedAnswer(selectedIndex: 1, text: nil, correct: false)
        let essay = SubmittedAnswer(selectedIndex: nil, text: "1", correct: nil)

        #expect(choice != essay)
        #expect(choice.text == nil)
        #expect(essay.selectedIndex == nil)
    }

}
