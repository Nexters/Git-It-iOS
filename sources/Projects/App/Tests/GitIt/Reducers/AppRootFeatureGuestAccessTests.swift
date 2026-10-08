import ComposableArchitecture
import Feature
import Testing

@testable import GitIt

@MainActor
@Suite("AppRootFeature 비로그인")
struct AppRootFeatureGuestAccessTests {

    // MARK: Internal

    @Test
    func `온보딩의 비로그인 진입 요청은 비로그인 메인 화면으로 이동하고 기기를 등록하지 않는다`() async {
        let appSetting = AppSettingUseCaseMock()
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .onboarding
        let store = makeAppRootStore(
            appSetting: appSetting,
            state: state,
        )

        await store.send(.onboarding(.delegate(.guestAccessRequested))) {
            $0.mainShell = MainShellRouterFeature.State(access: .guest)
            $0.route = .mainShell
        }

        #expect(store.state.deviceRegistration == .idle)
        #expect(await appSetting.registerDeviceCallCount == 0)
    }

    @Test
    func `비로그인에서 앱이 다시 활성화되면 로그인 검증과 재조회와 기기 등록을 하지 않는다`() async {
        let account = AccountUseCaseMock(verification: .reauthenticationRequired)
        let appSetting = AppSettingUseCaseMock()
        let project = ProjectUseCaseMock()
        var state = guestMainShellState()
        state.deviceRegistration = .failed
        let store = makeAppRootStore(
            account: account,
            appSetting: appSetting,
            project: project,
            state: state,
        )

        await store.send(.view(.applicationBecameActive))

        #expect(store.state.route == .mainShell)
        #expect(await account.verifyCallCount == 0)
        #expect(await project.refreshCallCount == 0)
        #expect(await appSetting.registerDeviceCallCount == 0)
    }

    @Test
    func `비로그인에서 재인증 필요 결과를 받아도 온보딩으로 돌아가지 않는다`() async {
        let store = makeAppRootStore(state: guestMainShellState())

        await store.send(.effect(.signInVerified(.reauthenticationRequired)))

        #expect(store.state.route == .mainShell)
        #expect(store.state.mainShell.access == .guest)
    }

    @Test
    func `비로그인에서 기기 토큰 갱신을 무시한다`() async {
        let appSetting = AppSettingUseCaseMock()
        let store = makeAppRootStore(
            appSetting: appSetting,
            state: guestMainShellState(),
        )

        await store.send(.effect(.deviceTokenRefreshed("device-token")))

        #expect(await appSetting.updatedDeviceTokens.isEmpty)
        #expect(await appSetting.registerDeviceCallCount == 0)
    }

    @Test
    func `추가 입력이 필요 없는 로그인 성공은 선택 탭을 유지한 채 로그인 사용자 메인 화면으로 바꾸고 기기를 등록한다`() async {
        let appSetting = AppSettingUseCaseMock()
        var state = guestMainShellState()
        state.mainShell.selectedTab = .settings
        let store = makeAppRootStore(
            appSetting: appSetting,
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.mainShell(.delegate(.signInSucceeded(needsCuration: false)))) {
            $0.deviceRegistration = .registering
        }
        await store.receive(.mainShell(.input(.memberAccessGranted)))

        #expect(store.state.route == .mainShell)
        #expect(store.state.mainShell.access == .member)
        #expect(store.state.mainShell.selectedTab == .settings)

        await store.skipReceivedActions()
        await store.finish()

        #expect(await appSetting.registerDeviceCallCount == 1)
    }

    @Test
    func `직군과 연차가 필요한 로그인 성공은 호출자 복귀 모드의 직군 선택으로 이동하고 메인 화면 상태를 유지한다`() async {
        let appSetting = AppSettingUseCaseMock()
        var state = guestMainShellState()
        state.mainShell.selectedTab = .settings
        let store = makeAppRootStore(
            appSetting: appSetting,
            state: state,
        )

        await store.send(.mainShell(.delegate(.signInSucceeded(needsCuration: true)))) {
            $0.onboarding = OnboardingRouterFeature.State(
                startingAt: .curation,
                bundleVersion: "1.0.0",
                curationExit: .returnToCaller,
            )
            $0.route = .onboarding
        }

        #expect(store.state.mainShell.access == .guest)
        #expect(store.state.mainShell.selectedTab == .settings)
        #expect(await appSetting.registerDeviceCallCount == 0)
    }

    @Test
    func `직군 선택을 중단하면 비로그인 메인 화면으로 돌아간다`() async {
        var state = guestMainShellState()
        state.route = .onboarding
        state.onboarding = OnboardingRouterFeature.State(
            startingAt: .curation,
            bundleVersion: "1.0.0",
            curationExit: .returnToCaller,
        )
        let store = makeAppRootStore(state: state)

        await store.send(.onboarding(.delegate(.curationAbandoned))) {
            $0.route = .mainShell
        }

        #expect(store.state.mainShell.access == .guest)
    }

    @Test
    func `직군과 연차를 마치면 선택 탭을 유지한 채 로그인 사용자 메인 화면으로 바뀐다`() async {
        let appSetting = AppSettingUseCaseMock()
        var state = guestMainShellState()
        state.mainShell.selectedTab = .settings
        state.route = .onboarding
        state.onboarding = OnboardingRouterFeature.State(
            startingAt: .curation,
            bundleVersion: "1.0.0",
            curationExit: .returnToCaller,
        )
        let store = makeAppRootStore(
            appSetting: appSetting,
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.onboarding(.delegate(.mainShellRequested))) {
            $0.route = .mainShell
            $0.deviceRegistration = .registering
        }
        await store.receive(.mainShell(.input(.memberAccessGranted)))

        #expect(store.state.mainShell.access == .member)
        #expect(store.state.mainShell.selectedTab == .settings)

        await store.skipReceivedActions()
        await store.finish()

        #expect(await appSetting.registerDeviceCallCount == 1)
    }

    @Test
    func `로그인 사용자의 로그아웃은 기존대로 튜토리얼 첫 면으로 이동한다`() async {
        let store = makeAppRootStore(state: AppRootTestFixture.mainShellState())
        store.exhaustivity = .off

        await store.send(.mainShell(.delegate(.loggedOut))) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(
                startingAt: .guide,
                bundleVersion: "1.0.0",
            )
        }

        #expect(store.state.onboarding.activeScreen == .guide(.tutorial))
        #expect(store.state.onboarding.tutorial.page == 1)
        #expect(store.state.mainShell.access == .member)
    }

    // MARK: Private

    private func guestMainShellState() -> AppRootFeature.State {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        state.mainShell = MainShellRouterFeature.State(access: .guest)
        return state
    }

}
