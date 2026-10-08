import ComposableArchitecture
import DomainQuizDetail
import Testing

@testable import Feature

@MainActor
@Suite("LearningSessionFeature 학습 세션 진행")
struct LearningSessionFeatureTests {

    // MARK: Internal

    @Test
    func `시작하면 첫 미응답 문제를 준비하고 세션 정답 수를 비운다`() async {
        let set = QuizTestFixture.partiallyAnsweredSet
        let resumption = LearningSetResumption(set: set)
        let store = makeStore()

        await store.send(.input(.started(
            set: set,
            resumption: resumption,
            bookmarkedQuestionIDs: ["quiz-2"],
        )))
        await store.receive(.delegate(.questionReady(
            question: set.quizzes[2],
            number: 3,
            isBookmarked: true,
            isLast: true,
        )))

        #expect(store.state.learningSet == set)
        #expect(store.state.resumption == resumption)
        #expect(store.state.currentQuestionIndex == 2)
        #expect(store.state.sessionCorrectChoiceCount == 0)
        #expect(store.state.isInProgress)
    }

    @Test
    func `시작 위치에 문제가 없으면 emptySetDetected를 보낸다`() async {
        let set = QuizTestFixture.emptySet
        let store = makeStore()

        await store.send(.input(.started(
            set: set,
            resumption: LearningSetResumption(set: set),
            bookmarkedQuestionIDs: [],
        )))
        await store.receive(.delegate(.emptySetDetected))

        #expect(!store.state.isInProgress)
    }

    @Test
    func `객관식 채점 결과만 세션 정답 수에 누적된다`() async {
        let store = makeStore()

        await store.send(.input(.answerRecorded(choiceCorrect: true)))
        #expect(store.state.sessionCorrectChoiceCount == 1)

        await store.send(.input(.answerRecorded(choiceCorrect: false)))
        await store.send(.input(.answerRecorded(choiceCorrect: nil)))
        #expect(store.state.sessionCorrectChoiceCount == 1)
    }

    @Test
    func `다음 문제가 있으면 advanced는 다음 문제를 준비한다`() async {
        let set = QuizTestFixture.unansweredSet
        let store = await startedStore(set: set)

        await store.send(.input(.advanced))
        await store.receive(.delegate(.questionReady(
            question: set.quizzes[1],
            number: 2,
            isBookmarked: false,
            isLast: false,
        )))

        #expect(store.state.currentQuestionIndex == 1)
    }

    @Test
    func `마지막 문제에서 advanced는 건너뛴 정답을 합산해 completed를 보낸다`() async {
        let set = QuizTestFixture.partiallyAnsweredSet
        let store = await startedStore(set: set)

        await store.send(.input(.answerRecorded(choiceCorrect: true)))
        await store.send(.input(.advanced))
        await store.receive(.delegate(.completed(
            correctChoiceCount: 2,
            choiceQuestionCount: 2,
        )))
    }

    @Test
    func `진행 중인 세션을 다시 시작하면 현재 문제와 정답 수를 유지한다`() async {
        let set = QuizTestFixture.unansweredSet
        let store = await startedStore(set: set)
        await store.send(.input(.answerRecorded(choiceCorrect: true)))
        await store.send(.input(.advanced))
        await store.receive(\.delegate.questionReady)

        await store.send(.input(.started(
            set: set,
            resumption: LearningSetResumption(set: set),
            bookmarkedQuestionIDs: ["quiz-0"],
        )))

        #expect(store.state.bookmarkedQuestionIDs == ["quiz-0"])
        #expect(store.state.currentQuestionIndex == 1)
        #expect(store.state.sessionCorrectChoiceCount == 1)
    }

    // MARK: Private

    private func makeStore() -> TestStoreOf<LearningSessionFeature> {
        let store = TestStore(initialState: LearningSessionFeature.State()) { LearningSessionFeature() }
        store.exhaustivity = .off
        return store
    }

    private func startedStore(set: QuizSet) async -> TestStoreOf<LearningSessionFeature> {
        let store = makeStore()
        await store.send(.input(.started(
            set: set,
            resumption: LearningSetResumption(set: set),
            bookmarkedQuestionIDs: [],
        )))
        await store.receive(\.delegate.questionReady)
        return store
    }

}
