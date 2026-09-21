import DomainAccount
import DomainUserInfo
import Testing

@testable import Feature

@MainActor
@Suite("OnboardingRouterFeature 화면 조합과 이동 추적")
struct OnboardingRouterFeatureTests {

    // MARK: Internal

    @Test
    func `정상 완료 여정은 guide와 curation 및 splash를 거쳐 mainShell 전환을 위임하고 이동 이벤트를 남긴다`() async {
        let signIn = AccountUseCaseSignInMock(results: [.signedIn(uncuratedAccount)])
        let policyConsent = AccountUseCaseConsentMock(status: OnboardingTestFixture.satisfiedConsentStatus)
        let userInfo = UserInfoUseCaseMock(curationResults: [.success(())])
        let store = makeOnboardingRouterStore(
            signIn: signIn,
            policyConsent: policyConsent,
            userInfo: userInfo,
        )
        store.exhaustivity = .off

        #expect(store.state.activeScreen == .guide(.tutorial))
        #expect(store.state.transitionLog.isEmpty)

        await store.send(.tutorial(.view(.appeared)))
        await store.receive(.tutorial(.signIn(.input(.prepareConsent))))
        await store.receive(.tutorial(.signIn(.legalAgreement(.input(.load)))))
        await store.receive(.tutorial(.signIn(.legalAgreement(.effect(.statusLoaded(
            requiredDocuments: OnboardingTestFixture.requiredDocuments,
            isStoredConsentValid: true,
        ))))))
        #expect(store.state.tutorial.signIn.legalAgreement.isStoredConsentValid)
        #expect(store.state.transitionLog.isEmpty)

        await store.send(.tutorial(.view(.appleSignInTapped)))
        await store.receive(.tutorial(.signIn(.effect(.signInFinished(
            requestID: 1,
            result: .signedIn(uncuratedAccount),
        )))))
        await store.receive(.tutorial(.delegate(.signInSucceeded(needsCuration: true))))

        #expect(store.state.activeScreen == .curation(.positionSelection))
        #expect(store.state.transitionLog.count == 1)
        #expect(store.state.transitionLog.last?.from == .guide(.tutorial))
        #expect(store.state.transitionLog.last?.to == .curation(.positionSelection))

        await store.send(.positionSelection(.view(.positionSelected(.ios))))
        #expect(store.state.transitionLog.count == 1)

        await store.send(.positionSelection(.view(.nextTapped)))
        await store.receive(.positionSelection(.delegate(.confirmed(.ios))))
        #expect(store.state.activeScreen == .curation(.careerSelection))
        #expect(store.state.careerSelection.position == .ios)
        #expect(store.state.transitionLog.count == 2)

        await store.send(.careerSelection(.view(.careerLevelSelected(.junior))))
        #expect(store.state.transitionLog.count == 2)

        await store.send(.careerSelection(.view(.submitTapped)))
        await store.receive(.careerSelection(.effect(.curationFinished(success: true))))
        await store.receive(.careerSelection(.delegate(.curationSucceeded)))
        await store.receive(.exit(.input(.curationSucceeded)))
        await store.receive(.exit(.delegate(.shouldExit)))

        #expect(store.state.activeScreen == .curationSplash)
        #expect(store.state.transitionLog.count == 3)
        #expect(store.state.transitionLog.last?.from == .curation(.careerSelection))
        #expect(store.state.transitionLog.last?.to == .curationSplash)

        await store.send(.view(.curationSplashFinished))
        await store.receive(.delegate(.mainShellRequested))

        #expect(await userInfo.snapshot().curations == [Curation(position: .ios, careerLevel: .junior)])
    }

    @Test
    func `로그인 취소는 화면을 바꾸지 않고 이동 이벤트를 남기지 않는다`() async {
        let signIn = AccountUseCaseSignInMock(results: [.cancelled])
        var state = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        state.tutorial.signIn.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.tutorial.signIn.legalAgreement.isStoredConsentValid = true
        let store = makeOnboardingRouterStore(signIn: signIn, state: state)
        store.exhaustivity = .off

        await store.send(.tutorial(.view(.appleSignInTapped)))
        await store.receive(.tutorial(.signIn(.effect(.signInFinished(requestID: 1, result: .cancelled)))))

        #expect(store.state.activeScreen == .guide(.tutorial))
        #expect(store.state.transitionLog.isEmpty)
        #expect(store.state.tutorial.signIn.phase == .cancelled)
    }

    @Test
    func `큐레이션 시작 지점으로 진입하면 curation positionSelection에서 시작한다`() {
        let state = OnboardingRouterFeature.State(startingAt: .curation, bundleVersion: "1.0.0")
        let store = makeOnboardingRouterStore(state: state)

        #expect(store.state.activeScreen == .curation(.positionSelection))
        #expect(store.state.transitionLog.isEmpty)
    }

    @Test
    func `career 화면에서 뒤로 가기는 positionSelection으로 되돌리고 두 선택을 모두 보존한다`() async {
        var state = OnboardingRouterFeature.State(startingAt: .curation, bundleVersion: "1.0.0")
        state.activeScreen = .curation(.careerSelection)
        state.positionSelection.position = .backend
        state.careerSelection.position = .backend
        state.careerSelection.careerLevel = .junior
        let store = makeOnboardingRouterStore(state: state)
        store.exhaustivity = .off

        await store.send(.careerSelection(.view(.backTapped)))
        await store.receive(.careerSelection(.delegate(.backRequested)))

        #expect(store.state.activeScreen == .curation(.positionSelection))
        #expect(store.state.positionSelection.position == .backend)
        #expect(store.state.careerSelection.careerLevel == .junior)
        #expect(store.state.transitionLog.last?.from == .curation(.careerSelection))
        #expect(store.state.transitionLog.last?.to == .curation(.positionSelection))
    }

    @Test
    func `포지션 선택 화면에서 뒤로 가기는 sign-out 성공 뒤 tutorial 마지막 페이지로 되돌아가고 큐레이션 선택을 초기화한다`() async {
        let state = OnboardingRouterFeature.State(startingAt: .curation, bundleVersion: "1.0.0")
        let signOut = AccountUseCaseSignOutMock(results: [.signedOut])
        let store = makeOnboardingRouterStore(signOut: signOut, state: state)
        store.exhaustivity = .off

        await store.send(.positionSelection(.view(.positionSelected(.backend))))
        await store.send(.positionSelection(.view(.backTapped)))
        await store.receive(.positionSelection(.effect(.signOutFinished(.signedOut))))
        await store.receive(.positionSelection(.delegate(.exitRequested)))
        await store.receive(.tutorial(.input(.returnToLastPage)))

        #expect(store.state.activeScreen == .guide(.tutorial))
        #expect(store.state.tutorial.page == 3)
        #expect(store.state.positionSelection.position == nil)
        #expect(store.state.careerSelection.careerLevel == nil)
        #expect(store.state.transitionLog.count == 1)
        #expect(store.state.transitionLog.last?.from == .curation(.positionSelection))
        #expect(store.state.transitionLog.last?.to == .guide(.tutorial))
    }

    @Test
    func `포지션 값만 바뀌는 액션은 이동 이벤트를 남기지 않는다`() async {
        let state = OnboardingRouterFeature.State(startingAt: .curation, bundleVersion: "1.0.0")
        let store = makeOnboardingRouterStore(state: state)

        await store.send(.positionSelection(.view(.positionSelected(.ios)))) {
            $0.positionSelection.position = .ios
        }

        #expect(store.state.transitionLog.isEmpty)
        #expect(store.state.activeScreen == .curation(.positionSelection))
    }

    @Test
    func `로그인 성공에서 needsCuration이 false이면 화면 전환 없이 mainShellRequested를 위임한다`() async {
        var state = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        state.tutorial.signIn.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.tutorial.signIn.legalAgreement.isStoredConsentValid = true
        let signIn = AccountUseCaseSignInMock(results: [.signedIn(curatedAccount)])
        let store = makeOnboardingRouterStore(signIn: signIn, state: state)
        store.exhaustivity = .off

        await store.send(.tutorial(.view(.appleSignInTapped)))
        await store.receive(.tutorial(.signIn(.effect(.signInFinished(
            requestID: 1,
            result: .signedIn(curatedAccount),
        )))))
        await store.receive(.tutorial(.delegate(.signInSucceeded(needsCuration: false))))
        await store.receive(.delegate(.mainShellRequested))

        #expect(store.state.activeScreen == .guide(.tutorial))
        #expect(store.state.transitionLog.isEmpty)
    }

    @Test
    func `튜토리얼의 비로그인 진입 요청은 약관 화면으로 이동하지 않고 guestAccessRequested로 전달한다`() async {
        let store = makeOnboardingRouterStore()

        await store.send(.tutorial(.view(.guestAccessTapped)))
        await store.receive(.tutorial(.delegate(.guestAccessRequested)))
        await store.receive(.delegate(.guestAccessRequested))

        #expect(store.state.activeScreen == .guide(.tutorial))
        #expect(store.state.transitionLog.isEmpty)
    }

    @Test
    func `호출자 복귀 모드에서 포지션 선택을 나가면 튜토리얼로 가지 않고 curationAbandoned를 위임한다`() async {
        let state = OnboardingRouterFeature.State(
            startingAt: .curation,
            bundleVersion: "1.0.0",
            curationExit: .returnToCaller,
        )
        let signOut = AccountUseCaseSignOutMock(results: [.signedOut])
        let store = makeOnboardingRouterStore(signOut: signOut, state: state)
        store.exhaustivity = .off

        await store.send(.positionSelection(.view(.positionSelected(.backend))))
        await store.send(.positionSelection(.view(.backTapped)))
        await store.receive(.positionSelection(.effect(.signOutFinished(.signedOut))))
        await store.receive(.positionSelection(.delegate(.exitRequested)))
        await store.receive(.delegate(.curationAbandoned))

        #expect(store.state.activeScreen == .curation(.positionSelection))
        #expect(store.state.positionSelection.position == nil)
        #expect(store.state.careerSelection.careerLevel == nil)
        #expect(store.state.transitionLog.isEmpty)
        #expect(await signOut.snapshot() == 1)
    }

    @Test
    func `중단 목적지를 지정하지 않으면 튜토리얼 복귀 모드로 시작한다`() {
        let state = OnboardingRouterFeature.State(startingAt: .curation, bundleVersion: "1.0.0")

        #expect(state.curationExit == .returnToTutorial)
    }

    // MARK: Private

    private let curatedAccount = OnboardingTestFixture.signedInAccount(needsCuration: false)
    private let uncuratedAccount = OnboardingTestFixture.signedInAccount(needsCuration: true)

}
