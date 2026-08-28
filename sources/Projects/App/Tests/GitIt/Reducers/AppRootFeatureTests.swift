import ComposableArchitecture
import DomainAuthentication
import Feature
import Testing

@testable import GitIt

@Suite("AppRootFeature root 전환")
struct AppRootFeatureTests {

    @Test
    func `launch task는 route를 즉시 바꾸지 않고 appEntry task를 전달한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.recoverableFailure])
        let observeAuthenticationOutcomes = ObserveAuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, observeAuthenticationOutcomes: observeAuthenticationOutcomes)
        store.exhaustivity = .off

        #expect(store.state.route == .restoring)

        await store.send(.view(.task))
        #expect(store.state.route == .restoring)
        #expect(store.state.appEntry.authentication == .retryableFailure)

        await observeAuthenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `미인증 세션은 route를 onboarding으로 전환하고 온보딩 안내부터 시작한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let observeAuthenticationOutcomes = ObserveAuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, observeAuthenticationOutcomes: observeAuthenticationOutcomes)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }

        await observeAuthenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `인증됐지만 프로필이 미완료면 route를 onboarding으로 전환하고 큐레이션부터 시작한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.authenticated(AppRootTestFixture.authenticatedUser)])
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.success(AppRootTestFixture.incompleteProfile)])
        let observeAuthenticationOutcomes = ObserveAuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
            observeAuthenticationOutcomes: observeAuthenticationOutcomes,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .curation, bundleVersion: "1.0.0")
        }

        await observeAuthenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `인증됐고 프로필이 완료면 route를 mainShell로 전환한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.authenticated(AppRootTestFixture.authenticatedUser)])
        let fetchMemberProfile = FetchMemberProfileUseCaseMock(results: [.success(AppRootTestFixture.completeProfile)])
        let observeAuthenticationOutcomes = ObserveAuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
            observeAuthenticationOutcomes: observeAuthenticationOutcomes,
        )
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .mainShell
        }

        await observeAuthenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `복원 가능한 실패는 route를 바꾸지 않고 재시도하면 목적지를 결정한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.recoverableFailure, .unauthenticated])
        let observeAuthenticationOutcomes = ObserveAuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, observeAuthenticationOutcomes: observeAuthenticationOutcomes)
        store.exhaustivity = .off

        await store.send(.view(.task))
        #expect(store.state.route == .restoring)
        #expect(store.state.appEntry.isShowingRecoverableError)

        await store.send(.appEntry(.view(.retryTapped)))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }

        await observeAuthenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `restoring을 벗어난 뒤 반복 task는 appEntry task를 다시 전달하지 않는다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let observeAuthenticationOutcomes = ObserveAuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, observeAuthenticationOutcomes: observeAuthenticationOutcomes)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }
        await store.send(.view(.task))

        #expect(await restoreSession.snapshot() == 1)

        await observeAuthenticationOutcomes.finish()
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
    func `onboarding delegate curationCompleted는 route를 curationSplash로 전환한다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .onboarding
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.onboarding(.delegate(.curationCompleted))) {
            $0.route = .curationSplash
        }
    }

    @Test
    func `curationSplash 완료는 route를 mainShell로 전환한다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .curationSplash
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.view(.curationSplashFinished)) {
            $0.route = .mainShell
        }
    }

    @Test
    func `curationSplash가 아닐 때 완료 신호는 route를 바꾸지 않는다`() async {
        var state = AppRootFeature.State(bundleVersion: "1.0.0")
        state.route = .mainShell
        let store = makeAppRootStore(state: state)
        store.exhaustivity = .off

        await store.send(.view(.curationSplashFinished))

        #expect(store.state.route == .mainShell)
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
    func `mainShell 표시 중 session invalidation은 onboarding 안내부터 다시 시작한다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let observeAuthenticationOutcomes = ObserveAuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, observeAuthenticationOutcomes: observeAuthenticationOutcomes)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }
        await store.send(.onboarding(.delegate(.mainShellRequested))) {
            $0.route = .mainShell
        }

        await observeAuthenticationOutcomes.emit(.unauthenticated)
        await store.receive(.effect(.authenticationOutcomeReceived(.unauthenticated))) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }

        await observeAuthenticationOutcomes.finish()
        await store.finish()
    }

    @Test
    func `onboarding 표시 중 session invalidation은 route를 바꾸지 않는다`() async {
        let restoreSession = RestoreSessionUseCaseMock(results: [.unauthenticated])
        let observeAuthenticationOutcomes = ObserveAuthenticationOutcomesUseCaseMock()
        let store = makeAppRootStore(restoreSession: restoreSession, observeAuthenticationOutcomes: observeAuthenticationOutcomes)
        store.exhaustivity = .off

        await store.send(.view(.task))
        await store.receive(\.appEntry.delegate.destinationDecided) {
            $0.route = .onboarding
            $0.onboarding = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        }

        await observeAuthenticationOutcomes.emit(.unauthenticated)
        await store.receive(.effect(.authenticationOutcomeReceived(.unauthenticated)))

        #expect(store.state.route == .onboarding)

        await observeAuthenticationOutcomes.finish()
        await store.finish()
    }

}
