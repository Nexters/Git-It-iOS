import ComposableArchitecture
import Testing

@testable import Feature

@MainActor
@Suite("MainShell 비로그인")
struct MainShellRouterFeatureGuestAccessTests {

    // MARK: Internal

    @Test
    func `비로그인이면 프로젝트와 저장 탭 선택을 무시하고 재조회를 보내지 않는다`() async {
        let projects = ProjectUseCaseMock()
        let store = makeStore(projects: projects)

        await store.send(.view(.tabSelected(.projects)))
        await store.send(.view(.tabSelected(.saved)))

        #expect(store.state.selectedTab == .home)
        #expect(await projects.snapshot().refreshCallCount == 0)
    }

    @Test
    func `비로그인에서 홈과 마이 탭 선택은 반영하되 재조회를 보내지 않는다`() async {
        let projects = ProjectUseCaseMock()
        let store = makeStore(projects: projects)

        await store.send(.view(.tabSelected(.settings))) {
            $0.selectedTab = .settings
        }
        await store.send(.view(.tabSelected(.home))) {
            $0.selectedTab = .home
        }

        #expect(await projects.snapshot().refreshCallCount == 0)
    }

    @Test
    func `비로그인에서 재조회 입력을 무시한다`() async {
        let projects = ProjectUseCaseMock()
        let store = makeStore(projects: projects)

        await store.send(.input(.learningProjectsReloadRequested))

        #expect(await projects.snapshot().refreshCallCount == 0)
    }

    @Test
    func `홈의 로그인 요청은 로그인 흐름을 시작한다`() async {
        let store = makeStore()
        store.exhaustivity = .off

        await store.send(.home(.delegate(.signInRequested)))
        await store.receive(.guestSignIn(.input(.start)))

        #expect(store.state.guestSignIn.phase != .idle)

        await store.finish()
    }

    @Test
    func `마이 탭 로그인 화면의 로그인은 로그인 흐름을 시작한다`() async {
        let store = makeStore()
        store.exhaustivity = .off

        await store.send(.view(.signInTapped))
        await store.receive(.guestSignIn(.input(.start)))

        #expect(store.state.guestSignIn.phase != .idle)

        await store.finish()
    }

    @Test
    func `로그인 성공은 직군 입력 필요 여부와 함께 signInSucceeded를 위임한다`() async {
        let store = makeStore()

        await store.send(.guestSignIn(.delegate(.signedIn(needsCuration: true))))
        await store.receive(.delegate(.signInSucceeded(needsCuration: true)))
    }

    @Test
    func `memberAccessGranted는 선택 탭을 유지한 채 로그인 사용자로 바꾸고 홈 적재와 재조회를 시작한다`() async {
        let projects = ProjectUseCaseMock()
        var state = MainShellRouterFeature.State(access: .guest)
        state.selectedTab = .settings
        let store = makeStore(state: state, projects: projects)
        store.exhaustivity = .off

        await store.send(.input(.memberAccessGranted)) {
            $0.access = .member
        }
        await store.receive(.home(.input(.accessChanged(.member))))
        await store.receive(.projectList(.input(.learningProjectsReloadRequested)))

        #expect(store.state.selectedTab == .settings)
        #expect(store.state.home.access == .member)

        await projects.finish()
        await store.skipInFlightEffects(strict: false)
    }

    // MARK: Private

    private func makeStore(
        state: MainShellRouterFeature.State = MainShellRouterFeature.State(access: .guest),
        projects: ProjectUseCaseMock = .init(),
        account: MainShellAccountUseCaseStub = .init(),
    ) -> TestStoreOf<MainShellRouterFeature> {
        TestStore(initialState: state) {
            MainShellRouterFeature(
                project: projects,
                quizDetail: QuizDetailUseCaseMock(),
                account: account,
                userInfo: UserInfoUseCaseMock(),
                appSetting: AppSettingUseCaseStub(),
            )
        }
    }

}
