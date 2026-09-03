import ComposableArchitecture
import DomainLearningProject
import Testing

@testable import Feature

@Suite("QuizRouterFeature 화면 전환과 완료 카운터")
struct QuizRouterFeatureTests {

    // MARK: Internal

    @Test
    func `시작하면 첫 미응답 문제로 전환하고 이동 원인을 기록한다`() async {
        let store = makeStore()
        store.exhaustivity = .off

        await store.send(.learningSetIntro(.delegate(.startRequested(
            set: QuizTestFixture.partiallyAnsweredSet,
            resumption: LearningSetResumption(set: QuizTestFixture.partiallyAnsweredSet),
            bookmarkedQuestionIDs: ["question-0"],
        ))))

        #expect(store.state.activeScreen == .questionSolving)
        #expect(store.state.currentQuestionIndex == 2)
        #expect(store.state.questionSolving?.question.questionID == "question-2")
        #expect(store.state.screenTransitions.map(\.cause) == [.startRequested])
        #expect(store.state.screenTransitions.map(\.from) == [.learningSetIntro])
        #expect(store.state.screenTransitions.map(\.to) == [.questionSolving])
    }

    @Test
    func `문제가 없는 세트는 전환하지 않고 소개 화면에 문제 없음을 알린다`() async {
        let store = makeStore()
        store.exhaustivity = .off

        await store.send(.learningSetIntro(.delegate(.startRequested(
            set: QuizTestFixture.emptySet,
            resumption: LearningSetResumption(set: QuizTestFixture.emptySet),
            bookmarkedQuestionIDs: [],
        ))))
        await store.receive(.learningSetIntro(.input(.emptySetReported)))

        #expect(store.state.activeScreen == .learningSetIntro)
        #expect(store.state.questionSolving == nil)
        #expect(store.state.screenTransitions.isEmpty)
    }

    @Test
    func `문제 화면 뒤로가기는 활성 화면만 되돌리고 진행 상태를 유지한다`() async {
        let store = makeStore()
        store.exhaustivity = .off
        await startFirstQuestion(store)

        await store.send(.questionSolving(.delegate(.backRequested)))

        #expect(store.state.activeScreen == .learningSetIntro)
        #expect(store.state.questionSolving != nil)
        #expect(store.state.screenTransitions.last?.cause == .backRequested)
    }

    @Test
    func `되돌아온 뒤 다시 시작하면 진행 중이던 문제를 이어서 푼다`() async {
        let store = makeStore()
        store.exhaustivity = .off
        await startFirstQuestion(store)
        await store.send(.questionSolving(.view(.choiceSelected(2))))
        await store.send(.questionSolving(.delegate(.backRequested)))

        await store.send(.learningSetIntro(.delegate(.startRequested(
            set: QuizTestFixture.unansweredSet,
            resumption: LearningSetResumption(set: QuizTestFixture.unansweredSet),
            bookmarkedQuestionIDs: [],
        ))))

        #expect(store.state.activeScreen == .questionSolving)
        #expect(store.state.currentQuestionIndex == 0)
        #expect(store.state.questionSolving?.draftChoiceIndex == 2)
    }

    @Test
    func `문제를 이동하면 활성 화면은 그대로이고 이전 문제 상태가 남지 않는다`() async {
        let store = makeStore()
        store.exhaustivity = .off
        await startFirstQuestion(store)
        await store.send(.questionSolving(.view(.choiceSelected(1))))

        await store.send(.questionSolving(.delegate(.advanceRequested)))

        #expect(store.state.activeScreen == .questionSolving)
        #expect(store.state.currentQuestionIndex == 1)
        #expect(store.state.questionSolving?.question.questionID == "question-1")
        #expect(store.state.questionSolving?.draftChoiceIndex == nil)
        #expect(store.state.questionSolving?.submission == .editing)
        #expect(store.state.screenTransitions.map(\.cause) == [.startRequested])
    }

    @Test
    func `건너뛴 정답을 포함해 완료 카운터를 채우고 완료 화면으로 전환한다`() async {
        let store = makeStore()
        store.exhaustivity = .off

        await store.send(.learningSetIntro(.delegate(.startRequested(
            set: QuizTestFixture.partiallyAnsweredSet,
            resumption: LearningSetResumption(set: QuizTestFixture.partiallyAnsweredSet),
            bookmarkedQuestionIDs: [],
        ))))
        await store.send(.questionSolving(.delegate(.advanceRequested)))

        #expect(store.state.activeScreen == .learningCompletion)
        #expect(store.state.learningCompletion.choiceQuestionCount == 2)
        #expect(store.state.learningCompletion.correctChoiceCount == 1)
        #expect(store.state.screenTransitions.last?.cause == .advancedToCompletion)
    }

    @Test
    func `객관식 채점 결과는 세션 정답 수에 누적되고 상위에 진행 갱신을 알린다`() async {
        let store = makeStore()
        store.exhaustivity = .off
        await startFirstQuestion(store)

        await store.send(.questionSolving(.delegate(.answerSubmitted(questionID: "question-0", choiceCorrect: true))))
        await store.receive(.delegate(.progressInvalidated(projectID: QuizTestFixture.projectID)))

        #expect(store.state.sessionCorrectChoiceCount == 1)

        await store.send(.questionSolving(.delegate(.answerSubmitted(questionID: "question-2", choiceCorrect: nil))))
        #expect(store.state.sessionCorrectChoiceCount == 1)
    }

    @Test
    func `소개 화면 뒤로가기와 완료 화면 닫기는 모두 흐름 이탈이다`() async {
        let store = makeStore()
        store.exhaustivity = .off

        await store.send(.learningSetIntro(.delegate(.backRequested)))
        await store.receive(.delegate(.dismissRequested(projectID: QuizTestFixture.projectID)))
        #expect(store.state.activeScreen == .learningSetIntro)

        await store.send(.learningCompletion(.delegate(.dismissRequested)))
        await store.receive(.delegate(.dismissRequested(projectID: QuizTestFixture.projectID)))
    }

    // MARK: Private

    private func startFirstQuestion(_ store: TestStoreOf<QuizRouterFeature>) async {
        await store.send(.learningSetIntro(.delegate(.startRequested(
            set: QuizTestFixture.unansweredSet,
            resumption: LearningSetResumption(set: QuizTestFixture.unansweredSet),
            bookmarkedQuestionIDs: [],
        ))))
    }

    private func makeStore() -> TestStoreOf<QuizRouterFeature> {
        TestStore(
            initialState: QuizRouterFeature.State(
                projectID: QuizTestFixture.projectID,
                setID: QuizTestFixture.setID,
                setLabel: QuizTestFixture.setLabel,
            )
        ) {
            QuizRouterFeature(
                fetchLearningSet: StubFetchLearningSetUseCase(results: [.success(QuizTestFixture.unansweredSet)]),
                fetchBookmarkedQuestions: StubFetchBookmarkedQuestionsUseCase(
                    results: [.success(QuizTestFixture.bookmarkCollection)]
                ),
                submitChoiceAnswer: StubSubmitChoiceAnswerUseCase(),
                submitEssayAnswer: StubSubmitEssayAnswerUseCase(),
                setQuestionBookmark: StubSetQuestionBookmarkUseCase(),
            )
        }
    }

}
