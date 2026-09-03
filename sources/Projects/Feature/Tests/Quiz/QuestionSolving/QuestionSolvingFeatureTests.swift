import ComposableArchitecture
import DomainLearningProject
import Foundation
import Testing

@testable import Feature

@Suite("QuestionSolvingFeature 답안 제출과 결과")
struct QuestionSolvingFeatureTests {

    // MARK: Internal

    @Test
    func `선택지를 다시 고르면 마지막 선택만 남는다`() async {
        let store = makeStore()

        await store.send(.view(.choiceSelected(1))) { $0.draftChoiceIndex = 1 }
        await store.send(.view(.choiceSelected(3))) { $0.draftChoiceIndex = 3 }
    }

    @Test
    func `선택하지 않으면 제출하지 않는다`() async {
        let submitChoiceAnswer = StubSubmitChoiceAnswerUseCase()
        let store = makeStore(submitChoiceAnswer: submitChoiceAnswer)

        await store.send(.view(.submitAnswerTapped))

        #expect(await submitChoiceAnswer.invocations.isEmpty)
    }

    @Test
    func `공백만 있는 서술형은 제출하지 않는다`() async {
        let submitEssayAnswer = StubSubmitEssayAnswerUseCase()
        let store = makeStore(
            submitEssayAnswer: submitEssayAnswer,
            state: essayState(draftEssayText: "   \n "),
        )

        await store.send(.view(.submitAnswerTapped))

        #expect(await submitEssayAnswer.invocations.isEmpty)
    }

    @Test
    func `서술형 입력은 400자를 넘기지 않는다`() async {
        let store = makeStore(state: essayState())
        let overflowingText = String(repeating: "가", count: 420)

        await store.send(.view(.essayTextChanged(overflowingText))) {
            $0.draftEssayText = String(repeating: "가", count: 400)
        }
        #expect(store.state.draftEssayText.count == QuestionSolvingFeature.essayCharacterLimit)
    }

    @Test
    func `제출 중에는 제출과 진행과 뒤로가기 입력을 모두 무시한다`() async {
        let submitChoiceAnswer = StubSubmitChoiceAnswerUseCase(
            results: [.success(QuizTestFixture.correctChoiceResult)]
        )
        var state = choiceState()
        state.draftChoiceIndex = 1
        state.submission = .submitting
        let store = makeStore(submitChoiceAnswer: submitChoiceAnswer, state: state)

        await store.send(.view(.submitAnswerTapped))
        await store.send(.view(.advanceTapped))
        await store.send(.view(.backTapped))

        #expect(await submitChoiceAnswer.invocations.isEmpty)
    }

    @Test
    func `제출에 실패하면 오류를 남기고 작성 중이던 답안을 보존한다`() async {
        let store = makeStore(
            submitEssayAnswer: StubSubmitEssayAnswerUseCase(results: [.failure(.temporarilyUnavailable)]),
            state: essayState(draftEssayText: "작성한 답안"),
        )
        store.exhaustivity = .off

        await store.send(.view(.submitAnswerTapped))
        await store.receive(\.effect.essayAnswerFinished)

        #expect(store.state.submission == .failed(.temporarilyUnavailable))
        #expect(store.state.draftEssayText == "작성한 답안")
    }

    @Test
    func `객관식 제출에 성공하면 결과 상태로 바뀌고 채점 결과를 상위로 알린다`() async {
        var state = choiceState()
        state.draftChoiceIndex = 1
        let store = makeStore(
            submitChoiceAnswer: StubSubmitChoiceAnswerUseCase(
                results: [.success(QuizTestFixture.correctChoiceResult)]
            ),
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.view(.submitAnswerTapped))
        await store.receive(\.effect.choiceAnswerFinished)
        await store.receive(
            .delegate(.answerSubmitted(questionID: state.question.questionID, choiceCorrect: true))
        )

        #expect(store.state.submission == .answered(.choice(QuizTestFixture.correctChoiceResult)))
    }

    @Test
    func `서술형 제출 결과는 정답 여부를 전달하지 않는다`() async {
        let state = essayState(draftEssayText: "작성한 답안")
        let store = makeStore(
            submitEssayAnswer: StubSubmitEssayAnswerUseCase(results: [.success(QuizTestFixture.essayResult)]),
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.view(.submitAnswerTapped))
        await store.receive(\.effect.essayAnswerFinished)
        await store.receive(
            .delegate(.answerSubmitted(questionID: state.question.questionID, choiceCorrect: nil))
        )
    }

    @Test
    func `출처 Sheet를 열고 닫아도 작성 중이던 상태가 유지된다`() async {
        var state = choiceState()
        state.draftChoiceIndex = 2
        let store = makeStore(state: state)

        await store.send(.view(.sourceTapped)) { $0.isSourceSheetPresented = true }
        await store.send(.view(.sourceSheetDismissed)) { $0.isSourceSheetPresented = false }

        #expect(store.state.draftChoiceIndex == 2)
    }

    @Test
    func `출처가 없으면 출처 컨트롤을 노출하지 않고 Sheet도 열리지 않는다`() async {
        let store = makeStore(state: choiceState(question: QuizTestFixture.questionWithoutSources))

        #expect(!store.state.isSourceControlPresented)

        await store.send(.view(.sourceTapped))

        #expect(!store.state.isSourceSheetPresented)
    }

    @Test
    func `출처 링크 입력은 외부 URL 열기 요청으로 상위에 올라간다`() async throws {
        let store = makeStore(state: choiceState(question: QuizTestFixture.questionWithManySources))
        let url = try #require(URL(string: "https://developer.apple.com/documentation/swiftui"))

        await store.send(.view(.sourceLinkTapped(url)))
        await store.receive(.delegate(.externalURLRequested(url)))
    }

    @Test
    func `북마크는 반영 중 재입력을 무시하고 같은 문제의 결과만 반영한다`() async {
        let setQuestionBookmark = StubSetQuestionBookmarkUseCase(results: [.success(BookmarkState(bookmarked: true))])
        let store = makeStore(setQuestionBookmark: setQuestionBookmark, state: choiceState())
        store.exhaustivity = .off

        await store.send(.view(.bookmarkToggleTapped))
        await store.send(.view(.bookmarkToggleTapped))
        await store.receive(\.effect.bookmarkFinished)

        #expect(await setQuestionBookmark.invocations.count == 1)
        #expect(store.state.isBookmarked)

        await store.send(
            .effect(.bookmarkFinished(questionID: "other-question", result: .success(BookmarkState(bookmarked: false))))
        )
        #expect(store.state.isBookmarked)
    }

    @Test
    func `결과 상태에서만 진행 입력이 상위로 올라간다`() async {
        var state = choiceState()
        state.submission = .answered(.choice(QuizTestFixture.correctChoiceResult))
        let store = makeStore(state: state)

        await store.send(.view(.advanceTapped))
        await store.receive(.delegate(.advanceRequested))
    }

    // MARK: Private

    private func choiceState(
        question: Question = QuizTestFixture.choiceQuestion(index: 0, myAnswer: nil),
        advanceActionTitle: String = "다음 문제",
    ) -> QuestionSolvingFeature.State {
        QuestionSolvingFeature.State(
            projectID: QuizTestFixture.projectID,
            question: question,
            questionNumber: 1,
            advanceActionTitle: advanceActionTitle,
        )
    }

    private func essayState(draftEssayText: String = "") -> QuestionSolvingFeature.State {
        var state = QuestionSolvingFeature.State(
            projectID: QuizTestFixture.projectID,
            question: QuizTestFixture.essayQuestion(index: 2, myAnswer: nil),
            questionNumber: 3,
            advanceActionTitle: "학습 완료",
        )
        state.draftEssayText = draftEssayText
        return state
    }

    private func makeStore(
        submitChoiceAnswer: StubSubmitChoiceAnswerUseCase = StubSubmitChoiceAnswerUseCase(),
        submitEssayAnswer: StubSubmitEssayAnswerUseCase = StubSubmitEssayAnswerUseCase(),
        setQuestionBookmark: StubSetQuestionBookmarkUseCase = StubSetQuestionBookmarkUseCase(),
        state: QuestionSolvingFeature.State? = nil,
    ) -> TestStoreOf<QuestionSolvingFeature> {
        TestStore(initialState: state ?? choiceState()) {
            QuestionSolvingFeature(
                submitChoiceAnswer: submitChoiceAnswer,
                submitEssayAnswer: submitEssayAnswer,
                setQuestionBookmark: setQuestionBookmark,
            )
        }
    }

}
