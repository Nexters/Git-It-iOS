import ComposableArchitecture
import DomainProject
import Testing

@testable import Feature

@MainActor
@Suite("HomeFeature 프로젝트 스트림 구독과 갱신")
struct HomeFeatureGenerationOutcomeTests {

    // MARK: Internal

    @Test
    func `task는 프로젝트 스트림을 구독하고 갱신을 한 번 요청한다`() async {
        let projects = ProjectUseCaseMock(initialList: HomeTestFixture.oneProjectPage)
        let store = makeStore(projects: projects)
        store.exhaustivity = .off

        let task = await store.send(.view(.task))
        await store.receive(\.effect.projectsReceived)

        #expect(store.state.projectLoad == .loaded(HomeTestFixture.oneProjectPage))
        while await projects.snapshot().refreshCallCount == 0 { await Task.yield() }
        #expect(await projects.snapshot().refreshCallCount == 1)
        #expect(await projects.activeSubscriptionCount() == 1)

        await projects.finish()
        await task.cancel()
    }

    @Test
    func `스트림이 다시 방출하면 최신 목록으로 갈아끼운다`() async {
        let projects = ProjectUseCaseMock(initialList: HomeTestFixture.oneProjectPage)
        let store = makeStore(projects: projects)
        store.exhaustivity = .off

        let task = await store.send(.view(.task))
        await store.receive(\.effect.projectsReceived)

        await projects.emit(HomeTestFixture.manyProjectsPage)
        await store.receive(\.effect.projectsReceived)

        #expect(store.state.projectLoad == .loaded(HomeTestFixture.manyProjectsPage))

        await projects.finish()
        await task.cancel()
    }

    @Test
    func `아직 적재되지 않은 목록은 표시 상태로 반영하지 않는다`() async {
        let store = makeStore()

        await store.send(.effect(.projectsReceived(
            ProjectList(summaries: [], hasNextPage: false, isLoaded: false)
        )))

        #expect(store.state.projectLoad == .idle)
    }

    @Test
    func `갱신에 실패해도 이미 적재된 목록을 오류로 덮지 않는다`() async {
        var state = HomeFeature.State()
        state.projectLoad = .loaded(HomeTestFixture.oneProjectPage)
        state.projectRequestID = 1
        let store = makeStore(state: state)

        await store.send(.effect(.refreshFinished(requestID: 1, error: .temporarilyUnavailable)))

        #expect(store.state.projectLoad == .loaded(HomeTestFixture.oneProjectPage))
    }

    @Test
    func `적재 전 갱신 실패는 오류 의미를 보존한다`() async {
        var state = HomeFeature.State()
        state.projectLoad = .loading
        state.projectRequestID = 1
        let store = makeStore(state: state)

        await store.send(.effect(.refreshFinished(requestID: 1, error: .temporarilyUnavailable))) {
            $0.projectLoad = .failed(.temporarilyUnavailable)
        }
    }

    @Test
    func `지난 요청의 갱신 결과는 반영하지 않는다`() async {
        var state = HomeFeature.State()
        state.projectLoad = .loading
        state.projectRequestID = 2
        let store = makeStore(state: state)

        await store.send(.effect(.refreshFinished(requestID: 1, error: .temporarilyUnavailable)))

        #expect(store.state.projectLoad == .loading)
    }

    @Test
    func `목록 재조회 입력은 갱신을 다시 요청한다`() async {
        let projects = ProjectUseCaseMock(initialList: HomeTestFixture.oneProjectPage)
        var state = HomeFeature.State()
        state.projectLoad = .loaded(HomeTestFixture.oneProjectPage)
        let store = makeStore(projects: projects, state: state)
        store.exhaustivity = .off

        await store.send(.input(.learningProjectsReloadRequested))
        await store.receive(\.effect.refreshFinished)

        #expect(store.state.projectRequestID == 1)
        #expect(store.state.projectLoad == .loaded(HomeTestFixture.oneProjectPage))
        #expect(await projects.snapshot().refreshCallCount == 1)
    }

    // MARK: Private

    private func makeStore(
        projects: ProjectUseCaseMock = ProjectUseCaseMock(),
        profile: UserInfoUseCaseSuspendableProfileMock = UserInfoUseCaseSuspendableProfileMock(
            results: [.success(HomeTestFixture.profileWithBoth)]
        ),
        state: HomeFeature.State = HomeFeature.State(),
    ) -> TestStoreOf<HomeFeature> {
        TestStore(initialState: state) {
            HomeFeature(
                projects: { await projects.projects() },
                refreshProjects: { try await projects.refresh() },
                profile: profile.fetchProfile,
            )
        }
    }

}
