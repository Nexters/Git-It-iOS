import ComposableArchitecture
import DomainLearningProject
import Testing

@testable import Feature

@Suite("SavedFeature 저장한 문제 목록")
struct SavedFeatureTests {

    // MARK: Internal

    @Test
    func `프로젝트 필터가 있으면 그 프로젝트로만 조회한다`() async {
        let fetchBookmarkedQuestions = StubFetchBookmarkedQuestionsUseCase(
            results: [.success(ProjectDetailTestFixture.savedQuestionCollection)]
        )
        let store = makeStore(
            fetchBookmarkedQuestions: fetchBookmarkedQuestions,
            state: SavedFeature.State(
                initialProjectFilter: ProjectDetailTestFixture.projectID,
                isBackControlPresented: true,
            ),
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.bookmarksLoadFinished)

        #expect(await fetchBookmarkedQuestions.requestedProjectIDs == [ProjectDetailTestFixture.projectID])
        #expect(store.state.collection?.bookmarks.allSatisfy { $0.projectID == ProjectDetailTestFixture.projectID } == true)
    }

    @Test
    func `프로젝트에서 진입해도 다른 프로젝트 필터로 바꿔 다시 조회한다`() async {
        let fetchBookmarkedQuestions = StubFetchBookmarkedQuestionsUseCase(
            results: [.success(ProjectDetailTestFixture.savedQuestionCollection)]
        )
        let store = makeStore(
            fetchBookmarkedQuestions: fetchBookmarkedQuestions,
            state: SavedFeature.State(initialProjectFilter: ProjectDetailTestFixture.projectID),
        )
        store.exhaustivity = .off

        await store.send(.view(.filterSelected(projectID: "project-2"))) {
            $0.selectedProjectID = "project-2"
        }
        await store.receive(\.effect.bookmarksLoadFinished)

        await store.send(.view(.filterSelected(projectID: nil))) {
            $0.selectedProjectID = nil
        }
        await store.receive(\.effect.bookmarksLoadFinished)

        #expect(await fetchBookmarkedQuestions.requestedProjectIDs == ["project-2", nil])
    }

    @Test
    func `이미 선택된 필터를 다시 누르면 조회하지 않는다`() async {
        let fetchBookmarkedQuestions = StubFetchBookmarkedQuestionsUseCase(
            results: [.success(ProjectDetailTestFixture.savedQuestionCollection)]
        )
        let store = makeStore(
            fetchBookmarkedQuestions: fetchBookmarkedQuestions,
            state: SavedFeature.State(initialProjectFilter: ProjectDetailTestFixture.projectID),
        )

        await store.send(.view(.filterSelected(projectID: ProjectDetailTestFixture.projectID)))

        #expect(await fetchBookmarkedQuestions.callCount == 0)
    }

    @Test
    func `목록을 표시하는 동안 세트 조회를 하지 않는다`() async {
        let fetchLearningSet = StubFetchLearningSetUseCase()
        let store = makeStore()
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.bookmarksLoadFinished)

        #expect(await fetchLearningSet.callCount == 0)
    }

    @Test
    func `저장한 문제가 없으면 빈 상태로 표시한다`() async {
        let store = makeStore(
            fetchBookmarkedQuestions: StubFetchBookmarkedQuestionsUseCase(
                results: [.success(ProjectDetailTestFixture.emptyQuestionCollection)]
            )
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.bookmarksLoadFinished)

        #expect(store.state.isEmpty)
    }

    @Test
    func `조회에 실패하면 오류를 남기고 재시도로 다시 조회한다`() async {
        let fetchBookmarkedQuestions = StubFetchBookmarkedQuestionsUseCase(results: [
            .failure(.temporarilyUnavailable),
            .success(ProjectDetailTestFixture.savedQuestionCollection),
        ])
        let store = makeStore(fetchBookmarkedQuestions: fetchBookmarkedQuestions)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.bookmarksLoadFinished)
        #expect(store.state.loadStatus == .failed(.temporarilyUnavailable))

        await store.send(.view(.retryTapped))
        await store.receive(\.effect.bookmarksLoadFinished)
        #expect(store.state.loadStatus == .loaded)
    }

    @Test
    func `문제 풀기 입력만 진입 의도를 만든다`() async {
        let question = ProjectDetailTestFixture.savedQuestionCollection.bookmarks[0]
        let store = makeStore()

        await store.send(.view(.solveTapped(question)))
        await store.receive(.delegate(.questionSelected(question)))
    }

    @Test
    func `뒤로가기 컨트롤을 표시하지 않는 흐름에서는 뒤로가기가 발생하지 않는다`() async {
        let store = makeStore(state: SavedFeature.State())

        await store.send(.view(.backTapped))
    }

    @Test
    func `북마크를 해제하면 목록에서 제거하지 않고 상태만 갱신한다`() async {
        let question = ProjectDetailTestFixture.savedQuestionCollection.bookmarks[0]
        let setQuestionBookmark = StubSetQuestionBookmarkUseCase(
            results: [.success(BookmarkState(bookmarked: false))]
        )
        let store = makeStore(setQuestionBookmark: setQuestionBookmark)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.bookmarksLoadFinished)

        await store.send(.view(.bookmarkToggleTapped(question)))
        await store.receive(\.effect.bookmarkToggleFinished) {
            $0.bookmarkOverrides[question.questionID] = false
            $0.bookmarkMutations[question.questionID] = .idle
        }

        #expect(await setQuestionBookmark.invocations == [
            StubSetQuestionBookmarkUseCase.Invocation(
                projectID: question.projectID,
                questionID: question.questionID,
                bookmarked: false,
            )
        ])
        #expect(store.state.collection?.bookmarks.contains(where: { $0.questionID == question.questionID }) == true)
    }

    // MARK: Private

    private func makeStore(
        fetchBookmarkedQuestions: StubFetchBookmarkedQuestionsUseCase = StubFetchBookmarkedQuestionsUseCase(
            results: [.success(ProjectDetailTestFixture.savedQuestionCollection)]
        ),
        setQuestionBookmark: StubSetQuestionBookmarkUseCase = StubSetQuestionBookmarkUseCase(),
        state: SavedFeature.State = SavedFeature.State(
            initialProjectFilter: ProjectDetailTestFixture.projectID,
            isBackControlPresented: true,
        ),
    ) -> TestStoreOf<SavedFeature> {
        TestStore(initialState: state) {
            SavedFeature(
                fetchBookmarkedQuestions: fetchBookmarkedQuestions,
                setQuestionBookmark: setQuestionBookmark,
            )
        }
    }

}
