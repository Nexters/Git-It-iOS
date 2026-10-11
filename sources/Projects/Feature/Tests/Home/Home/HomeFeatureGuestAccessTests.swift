import ComposableArchitecture
import Testing

@testable import Feature

@MainActor
@Suite("HomeFeature 비로그인")
struct HomeFeatureGuestAccessTests {

    // MARK: Internal

    @Test
    func `비로그인 task는 프로필과 프로젝트 요청을 보내지 않는다`() async {
        let projects = ProjectUseCaseMock(initialList: HomeTestFixture.oneProjectPage)
        let profile = UserInfoUseCaseSuspendableProfileMock(results: [.success(HomeTestFixture.profileWithBoth)])
        let store = makeStore(
            projects: projects,
            profile: profile,
            state: guestState(),
        )

        await store.send(.view(.task))

        #expect(await profile.snapshot().callCount == 0)
        #expect(await projects.snapshot().refreshCallCount == 0)
        #expect(await projects.activeSubscriptionCount() == 0)
    }

    @Test
    func `비로그인 재조회 입력은 프로젝트 요청을 보내지 않는다`() async {
        let projects = ProjectUseCaseMock()
        let store = makeStore(
            projects: projects,
            state: guestState(),
        )

        await store.send(.input(.learningProjectsReloadRequested))

        #expect(await projects.snapshot().refreshCallCount == 0)
    }

    @Test
    func `비로그인에서 등록을 누르면 등록 대신 signInRequired를 위임한다`() async {
        let store = makeStore(state: guestState())

        await store.send(.view(.projectRegistrationTapped))
        await store.receive(.delegate(.signInRequired))
    }

    @Test
    func `로그인 섹션의 로그인은 signInRequired를 위임한다`() async {
        let store = makeStore(state: guestState())

        await store.send(.view(.signInTapped))
        await store.receive(.delegate(.signInRequired))
    }

    @Test
    func `로그인 사용자로 바뀌면 프로필과 프로젝트 적재를 시작한다`() async {
        let projects = ProjectUseCaseMock(initialList: HomeTestFixture.oneProjectPage)
        let profile = UserInfoUseCaseSuspendableProfileMock(results: [.success(HomeTestFixture.profileWithBoth)])
        let store = makeStore(
            projects: projects,
            profile: profile,
            state: guestState(),
        )
        store.exhaustivity = .off

        let task = await store.send(.input(.accessChanged(.member)))

        #expect(store.state.access == .member)

        await store.receive(\.profile.input.load)
        await store.receive(\.profile.effect.profileLoadFinished)

        #expect(store.state.projectSummaries.requestID == 1)

        #expect(store.state.profile.load == .loaded(HomeTestFixture.profileWithBoth))
        #expect(await profile.snapshot().callCount == 1)

        await projects.finish()
        await task.cancel()
    }

    @Test
    func `비로그인에서 전체 보기를 누르면 allProjectsRequested 대신 signInRequired를 위임한다`() async {
        let store = makeStore(state: guestState())

        await store.send(.view(.showAllProjectsTapped))
        await store.receive(.delegate(.signInRequired))
    }

    // MARK: Private

    private func guestState() -> HomeFeature.State {
        var state = HomeFeature.State()
        state.access = .guest
        return state
    }

    private func makeStore(
        projects: ProjectUseCaseMock = ProjectUseCaseMock(),
        profile: UserInfoUseCaseSuspendableProfileMock = UserInfoUseCaseSuspendableProfileMock(
            results: [.success(HomeTestFixture.profileWithBoth)]
        ),
        state: HomeFeature.State,
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
