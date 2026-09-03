import ComposableArchitecture
import DomainLearningProject
import Testing

@testable import Feature

@Suite("LearningSetIntroFeature 세트 조회와 시작")
struct LearningSetIntroFeatureTests {

    // MARK: Internal

    @Test
    func `진입하면 세트와 북마크를 각각 한 번씩 조회한다`() async {
        let fetchLearningSet = StubFetchLearningSetUseCase(results: [.success(QuizTestFixture.unansweredSet)])
        let fetchBookmarkedQuestions = StubFetchBookmarkedQuestionsUseCase(
            results: [.success(QuizTestFixture.bookmarkCollection)]
        )
        let store = makeStore(
            fetchLearningSet: fetchLearningSet,
            fetchBookmarkedQuestions: fetchBookmarkedQuestions,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.setLoadFinished)
        await store.receive(\.effect.bookmarksLoadFinished)

        #expect(await fetchLearningSet.callCount == 1)
        #expect(await fetchBookmarkedQuestions.callCount == 1)
        #expect(store.state.learningSet == QuizTestFixture.unansweredSet)
        #expect(store.state.bookmarkedQuestionIDs == ["question-0"])
    }

    @Test
    func `북마크 조회가 실패해도 세트 조회 상태와 시작 가능 여부는 영향받지 않는다`() async {
        let store = makeStore(
            fetchLearningSet: StubFetchLearningSetUseCase(results: [.success(QuizTestFixture.unansweredSet)]),
            fetchBookmarkedQuestions: StubFetchBookmarkedQuestionsUseCase(results: [.failure(.notFound)]),
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.setLoadFinished)
        await store.receive(\.effect.bookmarksLoadFinished)

        #expect(store.state.setLoad == .loaded(QuizTestFixture.unansweredSet))
        #expect(store.state.bookmarkLoad == .failed(.notFound))
        #expect(store.state.bookmarkedQuestionIDs.isEmpty)
        #expect(store.state.isStartEnabled)
    }

    @Test
    func `세트 조회가 실패하면 오류 의미를 보존하고 재시도로 다시 조회한다`() async {
        let fetchLearningSet = StubFetchLearningSetUseCase(results: [
            .failure(.temporarilyUnavailable),
            .success(QuizTestFixture.unansweredSet),
        ])
        let store = makeStore(fetchLearningSet: fetchLearningSet)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.setLoadFinished)
        #expect(store.state.setLoad == .failed(.temporarilyUnavailable))

        await store.send(.view(.retryTapped))
        await store.receive(\.effect.setLoadFinished)
        #expect(store.state.setLoad == .loaded(QuizTestFixture.unansweredSet))
        #expect(await fetchLearningSet.callCount == 2)
    }

    @Test
    func `늦게 도착한 이전 요청 결과는 requestID가 달라 반영하지 않는다`() async {
        var state = LearningSetIntroFeature.State(projectID: "project-1", setID: "set-1", label: "CHAPTER 1")
        state.loadRequestID = 2
        state.setLoad = .loading(requestID: 2)
        let store = makeStore(state: state)

        await store.send(.effect(.setLoadFinished(requestID: 1, result: .success(QuizTestFixture.unansweredSet))))

        #expect(store.state.setLoad == .loading(requestID: 2))
    }

    @Test
    func `조회 중에는 시작 입력이 아무 일도 하지 않는다`() async {
        var state = LearningSetIntroFeature.State(projectID: "project-1", setID: "set-1", label: "CHAPTER 1")
        state.setLoad = .loading(requestID: 1)
        let store = makeStore(state: state)

        await store.send(.view(.startTapped))

        #expect(!store.state.isStartEnabled)
    }

    @Test
    func `문제 없음이 보고되면 시작 입력을 막는다`() async {
        var state = LearningSetIntroFeature.State(projectID: "project-1", setID: "set-1", label: "CHAPTER 1")
        state.setLoad = .loaded(QuizTestFixture.emptySet)
        let store = makeStore(state: state)

        await store.send(.input(.emptySetReported)) {
            $0.isEmptySetReported = true
        }
        await store.send(.view(.startTapped))

        #expect(!store.state.isStartEnabled)
    }

    @Test
    func `시작하면 세트와 이어풀기 정보와 북마크 목록을 함께 전달한다`() async {
        var state = LearningSetIntroFeature.State(projectID: "project-1", setID: "set-1", label: "CHAPTER 1")
        state.setLoad = .loaded(QuizTestFixture.partiallyAnsweredSet)
        state.bookmarkLoad = .loaded(["question-0"])
        let store = makeStore(state: state)

        await store.send(.view(.startTapped))
        await store.receive(
            .delegate(.startRequested(
                set: QuizTestFixture.partiallyAnsweredSet,
                resumption: LearningSetResumption(set: QuizTestFixture.partiallyAnsweredSet),
                bookmarkedQuestionIDs: ["question-0"],
            ))
        )
    }

    // MARK: Private

    private func makeStore(
        fetchLearningSet: StubFetchLearningSetUseCase = StubFetchLearningSetUseCase(
            results: [.success(QuizTestFixture.unansweredSet)]
        ),
        fetchBookmarkedQuestions: StubFetchBookmarkedQuestionsUseCase = StubFetchBookmarkedQuestionsUseCase(
            results: [.success(QuizTestFixture.bookmarkCollection)]
        ),
        state: LearningSetIntroFeature.State = LearningSetIntroFeature.State(
            projectID: "project-1",
            setID: "set-1",
            label: "CHAPTER 1",
        ),
    ) -> TestStoreOf<LearningSetIntroFeature> {
        TestStore(initialState: state) {
            LearningSetIntroFeature(
                fetchLearningSet: fetchLearningSet,
                fetchBookmarkedQuestions: fetchBookmarkedQuestions,
            )
        }
    }

}
