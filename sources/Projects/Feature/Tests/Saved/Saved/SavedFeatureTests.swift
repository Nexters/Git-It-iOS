import ComposableArchitecture
import DomainQuizDetail
import Testing

@testable import Feature

@MainActor
@Suite("SavedFeature 저장한 문제 목록")
struct SavedFeatureTests {

    // MARK: Internal

    @Test
    func `프로젝트 필터가 있으면 그 프로젝트로만 조회한다`() async {
        let fetchBookmarks = QuizDetailUseCaseBookmarkListStub(
            results: [.success(ProjectDetailTestFixture.savedQuizList)]
        )
        let store = makeStore(
            fetchBookmarks: fetchBookmarks,
            state: SavedFeature.State(
                initialProjectFilter: ProjectDetailTestFixture.projectID,
                isBackControlPresented: true,
            ),
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.bookmarksLoadFinished)

        #expect(await fetchBookmarks.requestedFilters == [.project(ProjectDetailTestFixture.projectID)])
        #expect(
            store.state.collection?.bookmarks
                .allSatisfy { $0.projectID == ProjectDetailTestFixture.projectID } == true
        )
    }

    @Test
    func `프로젝트에서 진입해도 다른 프로젝트 필터로 바꿔 다시 조회한다`() async {
        let fetchBookmarks = QuizDetailUseCaseBookmarkListStub(
            results: [.success(ProjectDetailTestFixture.savedQuizList)]
        )
        let store = makeStore(
            fetchBookmarks: fetchBookmarks,
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

        #expect(await fetchBookmarks.requestedFilters == [.project("project-2"), .all])
    }

    @Test
    func `이미 선택된 필터를 다시 누르면 조회하지 않는다`() async {
        let fetchBookmarks = QuizDetailUseCaseBookmarkListStub(
            results: [.success(ProjectDetailTestFixture.savedQuizList)]
        )
        let store = makeStore(
            fetchBookmarks: fetchBookmarks,
            state: SavedFeature.State(initialProjectFilter: ProjectDetailTestFixture.projectID),
        )

        await store.send(.view(.filterSelected(projectID: ProjectDetailTestFixture.projectID)))

        #expect(await fetchBookmarks.callCount == 0)
    }

    @Test
    func `목록을 표시하는 동안 세트 조회를 하지 않는다`() async {
        let fetchQuizSet = QuizDetailUseCaseQuizSetStub()
        let store = makeStore()
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.bookmarksLoadFinished)

        #expect(await fetchQuizSet.callCount == 0)
    }

    @Test
    func `저장한 문제가 없으면 빈 상태로 표시한다`() async {
        let store = makeStore(
            fetchBookmarks: QuizDetailUseCaseBookmarkListStub(
                results: [.success(ProjectDetailTestFixture.emptyQuizList)]
            )
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.bookmarksLoadFinished)

        #expect(store.state.isEmpty)
    }

    @Test
    func `조회에 실패하면 오류를 남기고 재시도로 다시 조회한다`() async {
        let fetchBookmarks = QuizDetailUseCaseBookmarkListStub(results: [
            .failure(.temporarilyUnavailable),
            .success(ProjectDetailTestFixture.savedQuizList),
        ])
        let store = makeStore(fetchBookmarks: fetchBookmarks)
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
        let bookmark = ProjectDetailTestFixture.savedQuizList.bookmarks[0]
        let store = makeStore()

        await store.send(.view(.solveTapped(bookmark)))
        await store.receive(.delegate(.questionSelected(bookmark)))
    }

    @Test
    func `뒤로가기 컨트롤을 표시하지 않는 흐름에서는 뒤로가기가 발생하지 않는다`() async {
        let store = makeStore(state: SavedFeature.State())

        await store.send(.view(.backTapped))
    }

    @Test
    func `북마크를 해제하면 목록에서 제거하지 않고 상태만 갱신한다`() async {
        let bookmark = ProjectDetailTestFixture.savedQuizList.bookmarks[0]
        let setBookmark = QuizDetailUseCaseBookmarkStub(
            results: [.success(QuizBookmarkState(quizID: bookmark.quizID, isBookmarked: false))]
        )
        let store = makeStore(setBookmark: setBookmark)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.effect.bookmarksLoadFinished)

        await store.send(.view(.bookmarkToggleTapped(bookmark)))
        await store.receive(\.effect.bookmarkToggleFinished) {
            $0.bookmarkOverrides[bookmark.quizID] = false
            $0.bookmarkMutations[bookmark.quizID] = .idle
        }

        #expect(await setBookmark.invocations == [
            QuizDetailUseCaseBookmarkStub.Invocation(
                quizID: bookmark.quizID,
                projectID: bookmark.projectID,
                isBookmarked: false,
            )
        ])
        #expect(store.state.collection?.bookmarks.contains(where: { $0.quizID == bookmark.quizID }) == true)
    }

    // MARK: Private

    private func makeStore(
        fetchBookmarks: QuizDetailUseCaseBookmarkListStub = QuizDetailUseCaseBookmarkListStub(
            results: [.success(ProjectDetailTestFixture.savedQuizList)]
        ),
        setBookmark: QuizDetailUseCaseBookmarkStub = QuizDetailUseCaseBookmarkStub(),
        state: SavedFeature.State = SavedFeature.State(
            initialProjectFilter: ProjectDetailTestFixture.projectID,
            isBackControlPresented: true,
        ),
    ) -> TestStoreOf<SavedFeature> {
        TestStore(initialState: state) {
            SavedFeature(
                fetchBookmarks: fetchBookmarks.fetchBookmarks,
                setBookmark: setBookmark.setBookmark,
            )
        }
    }

}
