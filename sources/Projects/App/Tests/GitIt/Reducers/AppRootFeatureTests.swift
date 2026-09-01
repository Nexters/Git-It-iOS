import ComposableArchitecture
import DomainAuthentication
import DomainLearningProject
import Feature
import Testing

@testable import GitIt

@Suite("AppRootFeature root 전환")
struct AppRootFeatureTests {

    @Test
    func `launch task는 route를 즉시 바꾸지 않고 appEntry task를 전달한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.recoverableFailure])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, authenticationOutcomes: authenticationOutcomes)
        store.exhaustivity = .off

        #expect(store.state.route == .restoring)

        await store.send(.view(.task))
        #expect(store.state.route == .restoring)
        #expect(store.state.appEntry.authentication == .retryableFailure)

        await authenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `미인증 세션은 route를 onboarding으로 전환하고 온보딩 안내부터 시작한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, authenticationOutcomes: authenticationOutcomes)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }

        await authenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `인증됐지만 프로필이 미완료면 route를 onboarding으로 전환하고 큐레이션부터 시작한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.authenticated(AppRootTestFixture.authenticatedUser)])
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.success(AppRootTestFixture.incompleteProfile)])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
            authenticationOutcomes: authenticationOutcomes,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .curation, bundleVersion: "1.0.0")
        }

        await authenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `인증됐고 프로필이 완료면 route를 mainShell로 전환한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.authenticated(AppRootTestFixture.authenticatedUser)])
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.success(AppRootTestFixture.completeProfile)])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
            authenticationOutcomes: authenticationOutcomes,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .mainShell
        }

        await authenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `복원 가능한 실패는 route를 바꾸지 않고 재시도하면 목적지를 결정한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.recoverableFailure, .unauthenticated])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, authenticationOutcomes: authenticationOutcomes)
        store.exhaustivity = .off

        await store.send(.view(.task))
        #expect(store.state.route == .restoring)
        #expect(store.state.appEntry.isShowingRecoverableError)

        await store.send(.appEntry(.view(.retryTapped)))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }

        await authenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `restoring을 벗어난 뒤 반복 task는 appEntry task를 다시 전달하지 않는다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, authenticationOutcomes: authenticationOutcomes)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }
        await store.send(.view(.task))

        #expect(await restoreSession.snapshot() == 1)

        await authenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `onboarding delegate mainShellRequested는 route를 mainShell로 전환한다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .onboarding
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.onboarding(.delegate(.mainShellRequested))) {
            $0.route = .mainShell
        }
    }

    @Test
    func `resetAll 탭은 주입된 초기화 동작을 실행한 뒤 onboarding 안내부터 다시 시작한다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        let spy = ResetAllForTestingSpy()
        let store = makeAppRootStore(resetAllForTesting: { await spy() }, state: state)
        store.exhaustivity = .off

        await store.send(.view(.resetAllTapped))
        await store.receive(.effect(.resetAllFinished)) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }

        #expect(await spy.callCount == 1)
    }

    @Test
    func `resetAll 탭은 주입된 초기화 동작이 없으면 아무 일도 하지 않는다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        let store = makeAppRootStore(state: state)

        await store.send(.view(.resetAllTapped))

        #expect(store.state.route == .mainShell)
    }

    @Test
    func `mainShell logout delegate는 onboarding 안내부터 다시 시작한다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.mainShell(.delegate(.loggedOut))) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }
    }

    @Test
    func `로그아웃·세션 무효화·초기화 뒤 재생성된 MainShell은 다음 진입에서 Home 기본으로 시작한다`() async {
        var loggedOutState = AppRootFeature.State(bundleVersion: "1.0.0")
        loggedOutState.route = .mainShell
        loggedOutState.mainShell.selectedTab = .settings
        let loggedOutStore = makeAppRootStore(state: loggedOutState)
        loggedOutStore.exhaustivity = .off

        await loggedOutStore.send(.mainShell(.delegate(.loggedOut))) {
            $0.route = .onboarding
            $0.mainShell = MainShellFeature.State()
        }
        await loggedOutStore.send(.onboarding(.delegate(.mainShellRequested))) {
            $0.route = .mainShell
        }
        #expect(loggedOutStore.state.mainShell.selectedTab == .home)
        #expect(loggedOutStore.state.mainShell.home == HomeFeature.State())

        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        var sessionState = AppRootFeature.State(bundleVersion: "1.0.0")
        sessionState.route = .mainShell
        sessionState.mainShell.selectedTab = .projects
        let sessionStore = makeAppRootStore(
            restoreSession: restoreSession,
            authenticationOutcomes: authenticationOutcomes,
            state: sessionState,
        )
        sessionStore.exhaustivity = .off

        await authenticationOutcomes.emit(.unauthenticated)
        await sessionStore.receive(.effect(.authenticationOutcomeReceived(.unauthenticated))) {
            $0.route = .onboarding
            $0.mainShell = MainShellFeature.State()
        }
        await sessionStore.send(.onboarding(.delegate(.mainShellRequested))) {
            $0.route = .mainShell
        }
        #expect(sessionStore.state.mainShell.selectedTab == .home)
        #expect(sessionStore.state.mainShell.home == HomeFeature.State())

        await authenticationOutcomes.finish()
        await sessionStore.finish()

        var resetState = AppRootFeature.State(bundleVersion: "1.0.0")
        resetState.route = .mainShell
        resetState.mainShell.selectedTab = .saved
        let spy = ResetAllForTestingSpy()
        let resetStore = makeAppRootStore(resetAllForTesting: { await spy() }, state: resetState)
        resetStore.exhaustivity = .off

        await resetStore.send(.view(.resetAllTapped))
        await resetStore.receive(.effect(.resetAllFinished)) {
            $0.route = .onboarding
            $0.mainShell = MainShellFeature.State()
        }
        await resetStore.send(.onboarding(.delegate(.mainShellRequested))) {
            $0.route = .mainShell
        }
        #expect(resetStore.state.mainShell.selectedTab == .home)
        #expect(resetStore.state.mainShell.home == HomeFeature.State())
    }

    @Test
    func `MainShell의 등록·ProjectDetail·학습 delegate는 payload를 보존하며 route와 MainShell 상태를 바꾸지 않는다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.mainShell(.delegate(.projectRegistrationRequested)))
        #expect(store.state.route == .mainShell)
        #expect(store.state.mainShell == MainShellFeature.State())

        await store.send(.mainShell(.delegate(.projectDetailRequested(projectID: "project-1"))))
        #expect(store.state.route == .mainShell)
        #expect(store.state.mainShell == MainShellFeature.State())

        await store.send(
            .mainShell(
                .delegate(
                    .learningRequested(projectID: "project-1", nextSetID: "set-1", nextQuestionID: "question-1")
                )
            )
        )
        #expect(store.state.route == .mainShell)
        #expect(store.state.mainShell == MainShellFeature.State())
    }

    @Test
    func `projectRegistrationRequested delegate는 등록 흐름 State를 채운다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.mainShell(.delegate(.projectRegistrationRequested))) {
            $0.projectRegistration = ProjectRegistrationFeature.State()
        }
    }

    @Test
    func `등록 완료 delegate는 등록 흐름을 닫고 Home을 정확히 한 번 재조회한다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        state.projectRegistration = ProjectRegistrationFeature.State()
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        let receipt = ProjectRegistrationReceipt(projectID: "project-1", requestStatus: "accepted", quizLevel: .l1)
        await store.send(.projectRegistration(.presented(.delegate(.projectRegistered(receipt))))) {
            $0.projectRegistration = nil
        }
        await store.receive(.mainShell(.home(.input(.learningProjectsReloadRequested))))
    }

    @Test
    func `mainShell 표시 중 session invalidation은 onboarding 안내부터 다시 시작한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, authenticationOutcomes: authenticationOutcomes)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }
        await store.send(.onboarding(.delegate(.mainShellRequested))) {
            $0.route = .mainShell
        }

        await authenticationOutcomes.emit(.unauthenticated)
        await store.receive(.effect(.authenticationOutcomeReceived(.unauthenticated))) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }

        await authenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `onboarding 표시 중 session invalidation은 route를 바꾸지 않는다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let authenticationOutcomes = AuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, authenticationOutcomes: authenticationOutcomes)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }

        await authenticationOutcomes.emit(.unauthenticated)
        await store.receive(.effect(.authenticationOutcomeReceived(.unauthenticated)))

        #expect(store.state.route == .onboarding)

        await authenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `인증 세션이 확립되면 기기 등록을 1회 수행한다`() async {
        let registerCurrentDevice = RegisterCurrentDeviceSpy()
        let store = makeAppRootStore(registerCurrentDevice: registerCurrentDevice)
        store.exhaustivity = .off

        await store.send(.appEntry(.delegate(.destinationDecided(.mainShell)))) {
            $0.route = .mainShell
            $0.deviceRegistration = .registering
        }
        await store.receive(.effect(.deviceRegistrationSucceeded)) {
            $0.deviceRegistration = .registered
        }

        #expect(await registerCurrentDevice.callCount == 1)
        await store.finish()
    }

    @Test
    func `기기 등록 실패는 상태로 남고 앱 활성화 시 재시도한다`() async {
        let registerCurrentDevice = RegisterCurrentDeviceSpy(results: [
            .failure(DeviceRegistrationTestError.failed),
            .success(()),
        ])
        let store = makeAppRootStore(registerCurrentDevice: registerCurrentDevice)
        store.exhaustivity = .off

        await store.send(.appEntry(.delegate(.destinationDecided(.mainShell))))
        await store.receive(.effect(.deviceRegistrationFailed)) {
            $0.deviceRegistration = .failed
        }

        await store.send(.view(.applicationBecameActive)) {
            $0.deviceRegistration = .registering
        }
        await store.receive(.effect(.deviceRegistrationSucceeded)) {
            $0.deviceRegistration = .registered
        }

        #expect(await registerCurrentDevice.callCount == 2)
        await store.finish()
    }

    @Test
    func `기기 등록 실패 후 token이 갱신되면 갱신 token으로 재시도한다`() async {
        let registerCurrentDevice = RegisterCurrentDeviceSpy(results: [
            .failure(DeviceRegistrationTestError.failed),
            .success(()),
        ])
        let store = makeAppRootStore(registerCurrentDevice: registerCurrentDevice)
        store.exhaustivity = .off

        await store.send(.appEntry(.delegate(.destinationDecided(.mainShell))))
        await store.receive(.effect(.deviceRegistrationFailed)) {
            $0.deviceRegistration = .failed
        }

        await store.send(.effect(.deviceTokenRefreshed)) {
            $0.deviceRegistration = .registering
        }
        await store.receive(.effect(.deviceRegistrationSucceeded)) {
            $0.deviceRegistration = .registered
        }

        #expect(await registerCurrentDevice.callCount == 2)
        await store.finish()
    }

    @Test
    func `앱 활성화와 token 갱신이 동시에 발생해도 서버 등록 요청은 1회다`() async {
        let registerCurrentDevice = RegisterCurrentDeviceSpy()
        await registerCurrentDevice.setSuspends(true)
        let store = makeAppRootStore(registerCurrentDevice: registerCurrentDevice)
        store.exhaustivity = .off

        await store.send(.appEntry(.delegate(.destinationDecided(.mainShell)))) {
            $0.route = .mainShell
            $0.deviceRegistration = .registering
        }

        // 진행 중인 등록이 있으므로 두 trigger 모두 새 요청을 만들지 않는다.
        await store.send(.view(.applicationBecameActive))
        await store.send(.effect(.deviceTokenRefreshed))

        #expect(await registerCurrentDevice.callCount == 1)

        await registerCurrentDevice.resumeOldest()
        await store.receive(.effect(.deviceRegistrationSucceeded)) {
            $0.deviceRegistration = .registered
        }
        await store.finish()
    }

    @Test
    func `인증 종료 시 등록 흐름 child와 기기 등록 상태를 함께 제거한다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        state.projectRegistration = ProjectRegistrationFeature.State()
        state.deviceRegistration = .failed
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.mainShell(.delegate(.loggedOut))) {
            $0.projectRegistration = nil
            $0.deviceRegistration = .idle
            $0.route = .onboarding
        }

        await store.finish()
    }

    @Test
    func `재로그인 시 이전 세션의 등록 흐름 화면이 다시 표시되지 않는다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        state.projectRegistration = ProjectRegistrationFeature.State()
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.mainShell(.delegate(.loggedOut))) {
            $0.projectRegistration = nil
            $0.route = .onboarding
        }
        await store.send(.onboarding(.delegate(.mainShellRequested))) {
            $0.route = .mainShell
            $0.deviceRegistration = .registering
        }

        #expect(store.state.projectRegistration == nil)

        await store.skipReceivedActions()
        await store.finish()
    }

}
