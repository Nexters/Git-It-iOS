import ComposableArchitecture
import Testing

@testable import Feature

@MainActor
@Suite("HomeFeature 조회")
struct HomeFeatureLoadTests {

    // MARK: Internal

    @Test
    func `최초 task는 프로필을 한 번만 조회하고 복귀 task는 갱신만 다시 요청한다`() async {
        let profile = UserInfoUseCaseSuspendableProfileMock(
            results: [.success(HomeTestFixture.profileWithBoth)],
            suspendsRequests: true,
        )
        let projects = ProjectUseCaseMock(initialList: HomeTestFixture.oneProjectPage)
        let store = makeStore(
            projects: projects,
            profile: profile,
        )
        store.exhaustivity = .off

        let firstTask = await store.send(.view(.task))
        await store.receive(\.profile.input.load)
        await store.receive(\.projectSummaries.input.start)

        #expect(store.state.profile.load == .loading)
        #expect(store.state.profile.requestID == 1)
        #expect(store.state.projectSummaries.requestID == 1)

        while await profile.snapshot().pendingCount == 0 { await Task.yield() }
        await profile.resumeNext()
        await store.receive(\.profile.effect.profileLoadFinished)

        #expect(store.state.profile.load == .loaded(HomeTestFixture.profileWithBoth))

        let secondTask = await store.send(.view(.task))
        await store.receive(\.projectSummaries.input.start)

        #expect(await profile.snapshot().callCount == 1)
        #expect(store.state.profile.requestID == 1)
        #expect(store.state.projectSummaries.requestID == 2)

        await projects.finish()
        await firstTask.cancel()
        await secondTask.cancel()
    }

    @Test
    func `프로필 재시도는 프로젝트를 보존하고 프로필 조회에 load만 보낸다`() async {
        let profile = UserInfoUseCaseSuspendableProfileMock(results: [.success(HomeTestFixture.profileWithBoth)])
        let projects = ProjectUseCaseMock(initialList: HomeTestFixture.oneProjectPage)
        var state = HomeFeature.State()
        state.profile.load = .failed(.temporarilyUnavailable)
        state.projectSummaries.load = .loaded(HomeTestFixture.oneProjectPage)
        let store = makeStore(
            projects: projects,
            profile: profile,
            state: state,
        )

        await store.send(.view(.profileRetryTapped))
        await store.receive(.profile(.input(.load))) {
            $0.profile.load = .loading
            $0.profile.requestID = 1
        }
        await store.receive(
            .profile(.effect(.profileLoadFinished(
                requestID: 1,
                result: .success(HomeTestFixture.profileWithBoth),
            )))
        ) {
            $0.profile.load = .loaded(HomeTestFixture.profileWithBoth)
        }

        #expect(store.state.projectSummaries.load == .loaded(HomeTestFixture.oneProjectPage))
        #expect(await profile.snapshot().callCount == 1)
        #expect(await projects.snapshot().refreshCallCount == 0)
    }

    @Test
    func `프로젝트 갱신 실패는 성공한 프로필을 보존하고 독립 실패 상태가 된다`() async {
        let profile = UserInfoUseCaseSuspendableProfileMock(
            results: [.success(HomeTestFixture.profileWithBoth)],
            suspendsRequests: true,
        )
        let projects = ProjectUseCaseMock(
            refreshResults: [.failure(.temporarilyUnavailable)],
            suspendsRefresh: true,
        )
        let store = makeStore(
            projects: projects,
            profile: profile,
        )
        store.exhaustivity = .off

        let task = await store.send(.view(.task))
        await store.receive(\.projectSummaries.input.start)

        #expect(store.state.projectSummaries.load == .loading)

        while await profile.snapshot().pendingCount == 0 { await Task.yield() }
        await profile.resumeNext()
        await store.receive(\.profile.effect.profileLoadFinished)

        while await projects.snapshot().pendingCount == 0 { await Task.yield() }
        await projects.resumeNext()
        await store.receive(\.projectSummaries.effect.refreshFinished)

        #expect(store.state.profile.load == .loaded(HomeTestFixture.profileWithBoth))
        #expect(store.state.projectSummaries.load == .failed(.temporarilyUnavailable))

        await projects.finish()
        await task.cancel()
    }

    @Test
    func `프로젝트 재시도는 프로필을 보존하고 목록에 refresh만 보낸다`() async {
        let profile = UserInfoUseCaseSuspendableProfileMock(results: [.success(HomeTestFixture.profileWithBoth)])
        let projects = ProjectUseCaseMock(initialList: HomeTestFixture.oneProjectPage)
        var state = HomeFeature.State()
        state.profile.load = .loaded(HomeTestFixture.profileWithBoth)
        state.projectSummaries.load = .failed(.temporarilyUnavailable)
        let store = makeStore(
            projects: projects,
            profile: profile,
            state: state,
        )

        await store.send(.view(.projectRetryTapped))
        await store.receive(.projectSummaries(.input(.refresh))) {
            $0.projectSummaries.load = .loading
            $0.projectSummaries.requestID = 1
        }
        await store.receive(.projectSummaries(.effect(.refreshFinished(
            requestID: 1,
            error: nil,
        ))))

        #expect(store.state.profile.load == .loaded(HomeTestFixture.profileWithBoth))
        #expect(await profile.snapshot().callCount == 0)
        #expect(await projects.snapshot().refreshCallCount == 1)
    }

    @Test
    func `실패 상태가 아니면 프로젝트 재시도는 아무 효과도 내지 않는다`() async {
        let projects = ProjectUseCaseMock(initialList: HomeTestFixture.oneProjectPage)
        var state = HomeFeature.State()
        state.projectSummaries.load = .loaded(HomeTestFixture.oneProjectPage)
        let store = makeStore(
            projects: projects,
            state: state,
        )

        await store.send(.view(.projectRetryTapped))

        #expect(store.state.projectSummaries.requestID == 0)
        #expect(await projects.snapshot().refreshCallCount == 0)
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
