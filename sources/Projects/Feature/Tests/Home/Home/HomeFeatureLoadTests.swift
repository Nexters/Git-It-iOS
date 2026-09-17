import ComposableArchitecture
import Testing

@testable import Feature

@MainActor
@Suite("HomeFeature 조회")
struct HomeFeatureLoadTests {

    // MARK: Internal

    @Test
    func `최초 task는 프로필을 한 번만 조회하고 복귀 task는 갱신만 다시 요청한다`() async {
        let profile = HomeMemberProfileUseCaseMock(
            results: [.success(HomeTestFixture.profileWithBoth)],
            suspendsRequests: true,
        )
        let projects = HomeLearningProjectsUseCaseMock(initialList: HomeTestFixture.oneProjectPage)
        let store = makeStore(projects: projects, profile: profile)
        store.exhaustivity = .off

        let firstTask = await store.send(.view(.task))

        #expect(store.state.profileLoad == .loading)
        #expect(store.state.profileRequestID == 1)
        #expect(store.state.projectRequestID == 1)

        while await profile.snapshot().pendingCount == 0 { await Task.yield() }
        await profile.resumeNext()
        await store.receive(\.effect.profileLoadFinished)

        #expect(store.state.profileLoad == .loaded(HomeTestFixture.profileWithBoth))

        let secondTask = await store.send(.view(.task))

        #expect(await profile.snapshot().callCount == 1)
        #expect(store.state.profileRequestID == 1)
        #expect(store.state.projectRequestID == 2)

        await projects.finish()
        await firstTask.cancel()
        await secondTask.cancel()
    }

    @Test
    func `프로필 재시도는 프로젝트를 보존하고 프로필만 조회한다`() async {
        let profile = HomeMemberProfileUseCaseMock(results: [.success(HomeTestFixture.profileWithBoth)])
        let projects = HomeLearningProjectsUseCaseMock(initialList: HomeTestFixture.oneProjectPage)
        var state = HomeFeature.State()
        state.profileLoad = .failed(.temporarilyUnavailable)
        state.projectLoad = .loaded(HomeTestFixture.oneProjectPage)
        let store = makeStore(projects: projects, profile: profile, state: state)

        await store.send(.view(.profileRetryTapped)) {
            $0.profileLoad = .loading
            $0.profileRequestID = 1
        }
        await store.receive(
            .effect(.profileLoadFinished(requestID: 1, result: .success(HomeTestFixture.profileWithBoth)))
        ) {
            $0.profileLoad = .loaded(HomeTestFixture.profileWithBoth)
        }

        #expect(store.state.projectLoad == .loaded(HomeTestFixture.oneProjectPage))
        #expect(await profile.snapshot().callCount == 1)
        #expect(await projects.snapshot().refreshCallCount == 0)
    }

    @Test
    func `현재 request ID와 다른 응답은 상태를 바꾸지 않는다`() async {
        var state = HomeFeature.State()
        state.profileLoad = .loading
        state.profileRequestID = 2
        let store = makeStore(state: state)

        await store.send(
            .effect(.profileLoadFinished(requestID: 1, result: .success(HomeTestFixture.profileWithBoth)))
        )

        #expect(store.state.profileLoad == .loading)
    }

    @Test
    func `프로젝트 갱신 실패는 성공한 프로필을 보존하고 독립 실패 상태가 된다`() async {
        let profile = HomeMemberProfileUseCaseMock(
            results: [.success(HomeTestFixture.profileWithBoth)],
            suspendsRequests: true,
        )
        let projects = HomeLearningProjectsUseCaseMock(
            refreshResults: [.failure(.temporarilyUnavailable)],
            suspendsRefresh: true,
        )
        let store = makeStore(projects: projects, profile: profile)
        store.exhaustivity = .off

        let task = await store.send(.view(.task))

        #expect(store.state.projectLoad == .loading)

        while await profile.snapshot().pendingCount == 0 { await Task.yield() }
        await profile.resumeNext()
        await store.receive(\.effect.profileLoadFinished)

        while await projects.snapshot().pendingCount == 0 { await Task.yield() }
        await projects.resumeNext()
        await store.receive(\.effect.refreshFinished)

        #expect(store.state.profileLoad == .loaded(HomeTestFixture.profileWithBoth))
        #expect(store.state.projectLoad == .failed(.temporarilyUnavailable))

        await projects.finish()
        await task.cancel()
    }

    @Test
    func `프로젝트 재시도는 프로필을 보존하고 갱신만 다시 요청한다`() async {
        let profile = HomeMemberProfileUseCaseMock(results: [.success(HomeTestFixture.profileWithBoth)])
        let projects = HomeLearningProjectsUseCaseMock(initialList: HomeTestFixture.oneProjectPage)
        var state = HomeFeature.State()
        state.profileLoad = .loaded(HomeTestFixture.profileWithBoth)
        state.projectLoad = .failed(.temporarilyUnavailable)
        let store = makeStore(projects: projects, profile: profile, state: state)

        await store.send(.view(.projectRetryTapped)) {
            $0.projectLoad = .loading
            $0.projectRequestID = 1
        }
        await store.receive(.effect(.refreshFinished(requestID: 1, error: nil)))

        #expect(store.state.profileLoad == .loaded(HomeTestFixture.profileWithBoth))
        #expect(await profile.snapshot().callCount == 0)
        #expect(await projects.snapshot().refreshCallCount == 1)
    }

    @Test
    func `실패 상태가 아니면 프로젝트 재시도는 아무 효과도 내지 않는다`() async {
        let projects = HomeLearningProjectsUseCaseMock(initialList: HomeTestFixture.oneProjectPage)
        var state = HomeFeature.State()
        state.projectLoad = .loaded(HomeTestFixture.oneProjectPage)
        let store = makeStore(projects: projects, state: state)

        await store.send(.view(.projectRetryTapped))

        #expect(store.state.projectRequestID == 0)
        #expect(await projects.snapshot().refreshCallCount == 0)
    }

    // MARK: Private

    private func makeStore(
        projects: HomeLearningProjectsUseCaseMock = HomeLearningProjectsUseCaseMock(),
        profile: HomeMemberProfileUseCaseMock = HomeMemberProfileUseCaseMock(
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
