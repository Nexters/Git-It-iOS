import DomainAuthentication
import DomainMember
import Testing

@testable import Feature

@Suite("OnboardingRouterFeature 화면 조합과 이동 추적")
struct OnboardingRouterFeatureTests {

    @Test
    func `정상 완료 여정은 guide와 curation 및 splash를 거쳐 mainShell 전환을 위임하고 이동 이벤트를 남긴다`() async {
        let signIn = SignInUseCaseMock(results: [.success(OnboardingTestFixture.authenticatedUser, needsCuration: true)])
        let policyConsent = PolicyConsentUseCaseMock(
            requiredDocuments: OnboardingTestFixture.requiredDocuments,
            storedConsentRecords: OnboardingTestFixture.validConsentRecords,
        )
        let completeCuration = CompleteCurationUseCaseMock(results: [.success(())])
        let store = makeOnboardingRouterStore(
            signIn: signIn,
            policyConsent: policyConsent,
            completeCuration: completeCuration,
        )
        store.exhaustivity = .off

        #expect(store.state.activeScreen == .guide(.tutorial))
        #expect(store.state.transitionLog.isEmpty)

        await store.send(.tutorial(.view(.appeared)))
        await store.receive(.tutorial(.delegate(.appeared)))
        await store.receive(.legalAgreement(.input(.load)))
        await store.receive(.legalAgreement(.effect(.documentsLoaded(
            requiredDocuments: OnboardingTestFixture.requiredDocuments,
            storedConsentRecords: OnboardingTestFixture.validConsentRecords,
        ))))
        #expect(store.state.legalAgreement.isStoredConsentValid)
        #expect(store.state.transitionLog.isEmpty)

        await store.send(.tutorial(.view(.appleSignInTapped)))
        await store.receive(.tutorial(.effect(.signInFinished(
            requestID: 1,
            result: .success(OnboardingTestFixture.authenticatedUser, needsCuration: true),
        ))))
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

        #expect(await completeCuration.snapshot() == [.init(position: .ios, careerLevel: .junior)])
    }

    @Test
    func `저장 동의가 유효하지 않으면 로그인 성공 뒤 legalAgreement 화면으로 이동하고 선택을 초기화한다`() async {
        var state = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        state.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legalAgreement.selectedDocumentIDs = [OnboardingTestFixture.privacyPolicy.identifier]
        let signIn = SignInUseCaseMock(results: [.success(OnboardingTestFixture.authenticatedUser, needsCuration: true)])
        let store = makeOnboardingRouterStore(signIn: signIn, state: state)
        store.exhaustivity = .off

        await store.send(.tutorial(.view(.appleSignInTapped)))
        await store.receive(.tutorial(.effect(.signInFinished(
            requestID: 1,
            result: .success(OnboardingTestFixture.authenticatedUser, needsCuration: true),
        ))))
        await store.receive(.tutorial(.delegate(.signInSucceeded(needsCuration: true))))
        await store.receive(.legalAgreement(.input(.prepare(needsCuration: true))))

        #expect(store.state.activeScreen == .guide(.legalAgreement))
        #expect(store.state.legalAgreement.selectedDocumentIDs.isEmpty)
        #expect(store.state.legalAgreement.pendingNeedsCuration == true)
        #expect(store.state.transitionLog.last?.to == .guide(.legalAgreement))
    }

    @Test
    func `동의를 마치면 tutorial로 돌아온 뒤 대기 중인 needsCuration에 따라 curation으로 이동한다`() async {
        var state = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        state.activeScreen = .guide(.legalAgreement)
        state.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legalAgreement.selectedDocumentIDs = Set(OnboardingTestFixture.requiredDocuments.map(\.identifier))
        state.legalAgreement.pendingNeedsCuration = true
        let store = makeOnboardingRouterStore(state: state)
        store.exhaustivity = .off

        await store.send(.legalAgreement(.view(.continueTapped)))
        await store.receive(.legalAgreement(.delegate(.consentCompleted(needsCuration: true))))

        #expect(store.state.activeScreen == .curation(.positionSelection))
    }

    @Test
    func `legalAgreement 취소는 tutorial 마지막 페이지로 되돌린다`() async {
        var state = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        state.activeScreen = .guide(.legalAgreement)
        state.tutorial.page = 3
        state.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
        let store = makeOnboardingRouterStore(state: state)
        store.exhaustivity = .off

        await store.send(.view(.legalAgreementDismissed))
        await store.receive(.legalAgreement(.view(.cancelTapped)))
        await store.receive(.legalAgreement(.delegate(.cancelled)))
        await store.receive(.tutorial(.input(.returnToLastPage)))

        #expect(store.state.activeScreen == .guide(.tutorial))
        #expect(store.state.tutorial.page == 3)
        #expect(store.state.legalAgreement.selectedDocumentIDs.isEmpty)
    }

    @Test
    func `로그인 취소는 화면을 바꾸지 않고 이동 이벤트를 남기지 않는다`() async {
        let signIn = SignInUseCaseMock(results: [.cancelled])
        let store = makeOnboardingRouterStore(signIn: signIn)
        store.exhaustivity = .off

        await store.send(.tutorial(.view(.appleSignInTapped)))
        await store.receive(.tutorial(.effect(.signInFinished(requestID: 1, result: .cancelled))))

        #expect(store.state.activeScreen == .guide(.tutorial))
        #expect(store.state.transitionLog.isEmpty)
        #expect(store.state.tutorial.authentication == .cancelled)
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
        let signOut = SignOutUseCaseMock(results: [.success])
        let store = makeOnboardingRouterStore(signOut: signOut, state: state)
        store.exhaustivity = .off

        await store.send(.positionSelection(.view(.positionSelected(.backend))))
        await store.send(.positionSelection(.view(.backTapped)))
        await store.receive(.positionSelection(.effect(.signOutFinished(.success))))
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
        state.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legalAgreement.storedConsentRecords = OnboardingTestFixture.validConsentRecords
        let signIn = SignInUseCaseMock(results: [.success(OnboardingTestFixture.authenticatedUser, needsCuration: false)])
        let store = makeOnboardingRouterStore(signIn: signIn, state: state)
        store.exhaustivity = .off

        await store.send(.tutorial(.view(.appleSignInTapped)))
        await store.receive(.tutorial(.effect(.signInFinished(
            requestID: 1,
            result: .success(OnboardingTestFixture.authenticatedUser, needsCuration: false),
        ))))
        await store.receive(.tutorial(.delegate(.signInSucceeded(needsCuration: false))))
        await store.receive(.delegate(.mainShellRequested))

        #expect(store.state.activeScreen == .guide(.tutorial))
        #expect(store.state.transitionLog.isEmpty)
    }

    @Test
    func `문서 sheet 닫기 view 액션은 legalAgreement의 표시 상태를 해제한다`() async {
        var state = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0")
        state.activeScreen = .guide(.legalAgreement)
        state.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legalAgreement.presentedDocumentID = OnboardingTestFixture.privacyPolicy.identifier
        let store = makeOnboardingRouterStore(state: state)
        store.exhaustivity = .off

        await store.send(.view(.legalDocumentSheetDismissed))
        await store.receive(.legalAgreement(.view(.documentSheetDismissed)))

        #expect(store.state.legalAgreement.presentedDocumentID == nil)
    }

}
