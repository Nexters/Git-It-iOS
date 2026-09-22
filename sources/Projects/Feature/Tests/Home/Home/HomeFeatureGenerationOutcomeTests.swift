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
        await store.receive(\.projectSummaries.effect.projectsReceived)

        #expect(store.state.projectSummaries.load == .loaded(HomeTestFixture.oneProjectPage))
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
        await store.receive(\.projectSummaries.effect.projectsReceived)

        await projects.emit(HomeTestFixture.manyProjectsPage)
        await store.receive(\.projectSummaries.effect.projectsReceived)

        #expect(store.state.projectSummaries.load == .loaded(HomeTestFixture.manyProjectsPage))

        await projects.finish()
        await task.cancel()
    }

    @Test
    func `목록 재조회 입력은 목록에 refresh를 보낸다`() async {
        let projects = ProjectUseCaseMock(initialList: HomeTestFixture.oneProjectPage)
        var state = HomeFeature.State()
        state.projectSummaries.load = .loaded(HomeTestFixture.oneProjectPage)
        let store = makeStore(
            projects: projects,
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.input(.learningProjectsReloadRequested))
        await store.receive(\.projectSummaries.effect.refreshFinished)

        #expect(store.state.projectSummaries.requestID == 1)
        #expect(store.state.projectSummaries.load == .loaded(HomeTestFixture.oneProjectPage))
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
