import ComposableArchitecture
import DomainLearningProject
import Testing

@testable import Feature

@Suite("SingleQuestionEntryFeature 단일 문제 준비")
struct SingleQuestionEntryFeatureTests {

    // MARK: Internal

    @Test
    func `세트 조회에 성공하면 대상 문제를 찾아 준비 완료를 알린다`() async {
        let store = makeStore()
        store.exhaustivity = .off

        await store.send(.input(.questionRequested(setID: "set-1", questionID: "question-1")))
        await store.receive(\.effect.setLoadFinished)
        await store.receive(
            .delegate(.questionPrepared(
                question: QuizTestFixture.unansweredSet.questions[1],
                projectID: ProjectDetailTestFixture.projectID,
            ))
        )
        #expect(store.state.preparation == .idle)
    }

    @Test
    func `세트에 문제가 없으면 준비 실패를 알린다`() async {
        let store = makeStore()
        store.exhaustivity = .off

        await store.send(.input(.questionRequested(setID: "set-1", questionID: "missing-question")))
        await store.receive(\.effect.setLoadFinished)
        await store.receive(.delegate(.preparationFailed(.questionUnavailable)))
        #expect(store.state.preparationError == .questionUnavailable)
    }

    @Test
    func `세트 조회가 실패하면 오류를 보존하고 준비 실패를 알린다`() async {
        let store = makeStore(
            fetchLearningSet: StubFetchLearningSetUseCase(results: [.failure(.temporarilyUnavailable)])
        )
        store.exhaustivity = .off

        await store.send(.input(.questionRequested(setID: "set-1", questionID: "question-0")))
        await store.receive(\.effect.setLoadFinished)
        await store.receive(.delegate(.preparationFailed(.temporarilyUnavailable)))
        #expect(store.state.preparationError == .temporarilyUnavailable)
    }

    @Test
    func `준비 중에는 같은 입력을 무시한다`() async {
        let fetchLearningSet = StubFetchLearningSetUseCase(results: [.success(QuizTestFixture.unansweredSet)])
        var state = SingleQuestionEntryFeature.State(projectID: ProjectDetailTestFixture.projectID)
        state.preparation = .loading(questionID: "question-0")
        let store = makeStore(fetchLearningSet: fetchLearningSet, state: state)

        await store.send(.input(.questionRequested(setID: "set-1", questionID: "question-0")))

        #expect(await fetchLearningSet.callCount == 0)
    }

    @Test
    func `진행 중인 문제와 다른 결과는 반영하지 않는다`() async {
        var state = SingleQuestionEntryFeature.State(projectID: ProjectDetailTestFixture.projectID)
        state.preparation = .loading(questionID: "question-0")
        let store = makeStore(state: state)

        await store.send(
            .effect(.setLoadFinished(questionID: "question-1", result: .success(QuizTestFixture.unansweredSet)))
        )

        #expect(store.state.preparation == .loading(questionID: "question-0"))
    }

    // MARK: Private

    private func makeStore(
        fetchLearningSet: StubFetchLearningSetUseCase = StubFetchLearningSetUseCase(
            results: [.success(QuizTestFixture.unansweredSet)]
        ),
        state: SingleQuestionEntryFeature.State = SingleQuestionEntryFeature.State(
            projectID: ProjectDetailTestFixture.projectID
        ),
    ) -> TestStoreOf<SingleQuestionEntryFeature> {
        TestStore(initialState: state) {
            SingleQuestionEntryFeature(fetchLearningSet: fetchLearningSet)
        }
    }

}
