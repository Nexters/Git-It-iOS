import ComposableArchitecture
import Testing

@testable import Feature

@MainActor
@Suite("MainShell 비로그인")
struct MainShellRouterFeatureGuestAccessTests {

    // MARK: Internal

    @Test(arguments: [MainShellTab.projects, .saved, .settings])
    func `비로그인에서 홈 외 탭을 누르면 탭을 바꾸지 않고 로그인 필요 알럿을 띄운다`(tab: MainShellTab) async {
        let projects = ProjectUseCaseMock()
        let store = makeStore(projects: projects)

        await store.send(.view(.tabSelected(tab))) {
            $0.isSignInRequiredAlertPresented = true
        }

        #expect(store.state.selectedTab == .home)
        #expect(await projects.snapshot().refreshCallCount == 0)
    }

    @Test
    func `비로그인에서 홈 탭 선택은 반영하되 재조회를 보내지 않는다`() async {
        let projects = ProjectUseCaseMock()
        var state = MainShellRouterFeature.State(access: .guest)
        state.selectedTab = .settings
        let store = makeStore(
            state: state,
            projects: projects,
        )

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
    func `홈의 로그인 필요 요청은 로그인 필요 알럿을 띄운다`() async {
        let store = makeStore()

        await store.send(.home(.delegate(.signInRequired))) {
            $0.isSignInRequiredAlertPresented = true
        }
    }

    @Test
    func `로그인 필요 알럿의 로그인은 알럿을 닫고 onboardingRequested를 위임한다`() async {
        var state = MainShellRouterFeature.State(access: .guest)
        state.isSignInRequiredAlertPresented = true
        let store = makeStore(state: state)

        await store.send(.view(.signInRequiredAlertSignInTapped)) {
            $0.isSignInRequiredAlertPresented = false
        }
        await store.receive(.delegate(.onboardingRequested))
    }

    @Test
    func `로그인 필요 알럿의 닫기는 알럿만 닫는다`() async {
        var state = MainShellRouterFeature.State(access: .guest)
        state.isSignInRequiredAlertPresented = true
        let store = makeStore(state: state)

        await store.send(.view(.signInRequiredAlertDismissed)) {
            $0.isSignInRequiredAlertPresented = false
        }
    }

    @Test
    func `memberAccessGranted는 선택 탭을 유지한 채 로그인 사용자로 바꾸고 홈 적재와 재조회를 시작한다`() async {
        let projects = ProjectUseCaseMock()
        var state = MainShellRouterFeature.State(access: .guest)
        state.selectedTab = .settings
        let store = makeStore(
            state: state,
            projects: projects,
        )
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
