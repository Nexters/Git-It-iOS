import DomainAuthentication
import DomainMember
import Testing

@testable import Feature

@Suite("OnboardingRouterFeature 화면 조합과 이동 추적")
struct OnboardingRouterFeatureTests {

    @Test
    func `정상 완료 여정은 guide와 curation 및 splash를 거쳐 mainShell 전환을 위임하고 이동 이벤트를 남긴다`() async {
        let signIn = SignInUseCaseMock(results: [.success(OnboardingTestFixture.authenticatedUser, needsCuration: true)])
        let completeCuration = CompleteCurationUseCaseMock(results: [.success(())])
        let store = makeOnboardingRouterStore(signIn: signIn, completeCuration: completeCuration)
        store.exhaustivity = .off

        #expect(store.state.activeScreen == .guide(.tutorial(page: 1)))
        #expect(store.state.transitionLog.isEmpty)

        await store.send(.guide(.view(.tutorialPageChanged(3))))
        #expect(store.state.activeScreen == .guide(.tutorial(page: 3)))
        #expect(store.state.transitionLog.count == 1)
        #expect(store.state.transitionLog.last?.from == .guide(.tutorial(page: 1)))
        #expect(store.state.transitionLog.last?.to == .guide(.tutorial(page: 3)))

        await store.send(.guide(.view(.appleSignInTapped)))
        await store.receive(.guide(.effect(.signInFinished(
            requestID: 1,
            result: .success(OnboardingTestFixture.authenticatedUser, needsCuration: true),
        ))))
        await store.receive(.guide(.delegate(.signInSucceeded(needsCuration: true))))

        #expect(store.state.activeScreen == .curation(.position))
        #expect(store.state.transitionLog.count == 2)
        #expect(store.state.transitionLog.last?.from == .guide(.tutorial(page: 3)))
        #expect(store.state.transitionLog.last?.to == .curation(.position))

        await store.send(.curation(.view(.positionSelected(.ios))))
        #expect(store.state.transitionLog.count == 2)

        await store.send(.curation(.view(.positionNextTapped)))
        #expect(store.state.activeScreen == .curation(.career))
        #expect(store.state.transitionLog.count == 3)

        await store.send(.curation(.view(.careerLevelSelected(.junior))))
        #expect(store.state.transitionLog.count == 3)

        await store.send(.curation(.view(.curationSubmitTapped)))
        await store.receive(.curation(.effect(.curationFinished(success: true))))
        await store.receive(.curation(.delegate(.curationSucceeded)))
        await store.receive(.exit(.input(.curationSucceeded)))
        await store.receive(.exit(.delegate(.shouldExit))) {
            $0.activeScreen = .curationSplash
            $0.transitionLog.append(.init(
                from: .curation(.career),
                to: .curationSplash,
                trigger: String(describing: OnboardingRouterFeature.Action.exit(.delegate(.shouldExit))),
            ))
        }

        #expect(store.state.activeScreen == .curationSplash)
        #expect(store.state.transitionLog.count == 4)

        await store.send(.view(.curationSplashFinished))
        await store.receive(.delegate(.mainShellRequested))

        #expect(await completeCuration.snapshot() == [.init(position: .ios, careerLevel: .junior)])
    }

    @Test
    func `로그인 취소는 화면을 바꾸지 않고 이동 이벤트를 남기지 않는다`() async {
        let signIn = SignInUseCaseMock(results: [.cancelled])
        let store = makeOnboardingRouterStore(signIn: signIn)
        store.exhaustivity = .off

        await store.send(.guide(.view(.appleSignInTapped)))
        await store.receive(.guide(.effect(.signInFinished(requestID: 1, result: .cancelled))))

        #expect(store.state.activeScreen == .guide(.tutorial(page: 1)))
        #expect(store.state.transitionLog.isEmpty)
        #expect(store.state.guide.authentication == .cancelled)
    }

    @Test
    func `큐레이션 시작 지점으로 진입하면 curation position에서 시작한다`() {
        let state = OnboardingRouterFeature.State(startingAt: .curation, bundleVersion: "1.0.0")
        let store = makeOnboardingRouterStore(state: state)

        #expect(store.state.activeScreen == .curation(.position))
        #expect(store.state.transitionLog.isEmpty)
    }

    @Test
    func `포지션 선택 화면에서 뒤로 가기는 sign-out 성공 뒤 온보딩 안내 3페이지로 되돌아가고 큐레이션 선택을 초기화하며 이동 이벤트를 남긴다`() async {
        let state = OnboardingRouterFeature.State(startingAt: .curation, bundleVersion: "1.0.0")
        let signOut = SignOutUseCaseMock(results: [.success])
        let store = makeOnboardingRouterStore(signOut: signOut, state: state)
        store.exhaustivity = .off

        await store.send(.curation(.view(.positionSelected(.backend))))
        await store.send(.curation(.view(.positionBackTapped)))
        await store.receive(.curation(.effect(.positionExitSignOutFinished(.success))))
        await store.receive(.curation(.delegate(.exitRequested))) {
            $0.guide.screen = .tutorial(page: 3)
            $0.curation = CurationFeature.State()
        }

        #expect(store.state.activeScreen == .guide(.tutorial(page: 3)))
        #expect(store.state.curation.selection.position == nil)
        #expect(store.state.transitionLog.count == 1)
        #expect(store.state.transitionLog.last?.from == .curation(.position))
        #expect(store.state.transitionLog.last?.to == .guide(.tutorial(page: 3)))
    }

    @Test
    func `포지션 값만 바뀌는 액션은 이동 이벤트를 남기지 않는다`() async {
        let state = OnboardingRouterFeature.State(startingAt: .curation, bundleVersion: "1.0.0")
        let store = makeOnboardingRouterStore(state: state)

        await store.send(.curation(.view(.positionSelected(.ios)))) {
            $0.curation.selection.position = .ios
        }

        #expect(store.state.transitionLog.isEmpty)
        #expect(store.state.activeScreen == .curation(.position))
    }

    @Test
    func `로그인 성공에서 needsCuration이 false이면 화면 전환 없이 mainShellRequested를 위임한다`() async {
        let signIn = SignInUseCaseMock(results: [.success(OnboardingTestFixture.authenticatedUser, needsCuration: false)])
        let store = makeOnboardingRouterStore(signIn: signIn)
        store.exhaustivity = .off

        await store.send(.guide(.view(.appleSignInTapped)))
        await store.receive(.guide(.effect(.signInFinished(
            requestID: 1,
            result: .success(OnboardingTestFixture.authenticatedUser, needsCuration: false),
        ))))
        await store.receive(.guide(.delegate(.signInSucceeded(needsCuration: false))))
        await store.receive(.delegate(.mainShellRequested))

        #expect(store.state.activeScreen == .guide(.tutorial(page: 1)))
        #expect(store.state.transitionLog.isEmpty)
    }

}
