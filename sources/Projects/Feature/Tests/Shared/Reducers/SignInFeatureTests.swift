import ComposableArchitecture
import DomainAccount
import Testing

@testable import Feature

@MainActor
@Suite("SignInFeature 약관 동의를 포함한 로그인")
struct SignInFeatureTests {

    // MARK: Internal

    @Test
    func `prepareConsent는 동의 상태를 적재한다`() async {
        let account = MainShellAccountUseCaseStub(consentStatus: OnboardingTestFixture.satisfiedConsentStatus)
        let store = makeStore(account: account)

        await store.send(.input(.prepareConsent))
        await store.receive(.legalAgreement(.input(.load)))
        await store.receive(.legalAgreement(.effect(.statusLoaded(
            requiredDocuments: OnboardingTestFixture.requiredDocuments,
            isStoredConsentValid: true,
        )))) {
            $0.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
            $0.legalAgreement.isStoredConsentValid = true
        }

        #expect(store.state.phase == .idle)
    }

    @Test
    func `이미 적재된 동의 상태는 prepareConsent로 다시 적재하지 않는다`() async {
        let store = makeStore(account: MainShellAccountUseCaseStub(), state: consentCheckedState())

        await store.send(.input(.prepareConsent))
    }

    @Test
    func `약관 동의가 충족되면 바로 Apple 로그인을 시작한다`() async {
        let account = MainShellAccountUseCaseStub(
            signInResults: [.signedIn(curatedAccount)],
            consentStatus: OnboardingTestFixture.satisfiedConsentStatus,
        )
        let store = makeStore(account: account)

        await store.send(.input(.start)) {
            $0.phase = .checkingConsent
        }
        await store.receive(.legalAgreement(.input(.load)))
        await store.receive(.legalAgreement(.effect(.statusLoaded(
            requiredDocuments: OnboardingTestFixture.requiredDocuments,
            isStoredConsentValid: true,
        )))) {
            $0.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
            $0.legalAgreement.isStoredConsentValid = true
            $0.phase = .signingIn
            $0.requestID = 1
        }
        await store.receive(.effect(.signInFinished(requestID: 1, result: .signedIn(curatedAccount)))) {
            $0.phase = .idle
        }
        await store.receive(.delegate(.signedIn(needsCuration: false)))

        #expect(await account.snapshot().signInMethods == [.apple])
    }

    @Test
    func `동의 상태가 적재되기 전의 start는 적재 완료를 기다린 뒤 동의 필요 여부를 판단한다`() async {
        let account = MainShellAccountUseCaseStub(consentStatus: OnboardingTestFixture.pendingConsentStatus)
        let store = makeStore(account: account)

        await store.send(.input(.start)) {
            $0.phase = .checkingConsent
        }

        #expect(!store.state.isLegalAgreementPresented)

        await store.receive(.legalAgreement(.input(.load)))
        await store.receive(.legalAgreement(.effect(.statusLoaded(
            requiredDocuments: OnboardingTestFixture.requiredDocuments,
            isStoredConsentValid: false,
        )))) {
            $0.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
            $0.phase = .agreeingToPolicies
        }
        await store.receive(.legalAgreement(.input(.prepare)))

        #expect(store.state.isLegalAgreementPresented)
        #expect(await account.snapshot().signInMethods.isEmpty)
    }

    @Test
    func `약관 동의를 마치면 로그인한다`() async {
        let account = MainShellAccountUseCaseStub(signInResults: [.signedIn(curatedAccount)])
        var state = SignInFeature.State()
        state.phase = .agreeingToPolicies
        state.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
        let store = makeStore(account: account, state: state)
        let documentIDs = Set(OnboardingTestFixture.requiredDocuments.map(\.id))

        await store.send(.legalAgreement(.view(.allDocumentsToggled))) {
            $0.legalAgreement.selectedDocumentIDs = documentIDs
        }
        await store.send(.legalAgreement(.view(.continueTapped))) {
            $0.legalAgreement.isStoredConsentValid = true
        }
        await store.receive(.legalAgreement(.delegate(.consentCompleted))) {
            $0.phase = .signingIn
            $0.requestID = 1
        }
        await store.receive(.effect(.signInFinished(requestID: 1, result: .signedIn(curatedAccount)))) {
            $0.phase = .idle
        }
        await store.receive(.delegate(.signedIn(needsCuration: false)))

        #expect(await account.snapshot().signInMethods == [.apple])
    }

    @Test
    func `약관 동의를 취소하면 로그인 없이 대기 상태로 돌아가고 consentCancelled를 보낸다`() async {
        let account = MainShellAccountUseCaseStub()
        var state = SignInFeature.State()
        state.phase = .agreeingToPolicies
        state.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
        let store = makeStore(account: account, state: state)

        await store.send(.view(.legalAgreementDismissed))
        await store.receive(.legalAgreement(.view(.cancelTapped)))
        await store.receive(.legalAgreement(.delegate(.cancelled))) {
            $0.phase = .idle
        }
        await store.receive(.delegate(.consentCancelled))

        #expect(await account.snapshot().signInMethods.isEmpty)
    }

    @Test
    func `문서 sheet 닫기는 legalAgreement의 문서 표시를 해제한다`() async {
        var state = SignInFeature.State()
        state.phase = .agreeingToPolicies
        state.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legalAgreement.presentedDocumentID = OnboardingTestFixture.privacyPolicy.id
        let store = makeStore(account: MainShellAccountUseCaseStub(), state: state)
        store.exhaustivity = .off

        await store.send(.view(.legalDocumentSheetDismissed))
        await store.receive(.legalAgreement(.view(.documentSheetDismissed)))

        #expect(store.state.legalAgreement.presentedDocumentID == nil)
        #expect(store.state.phase == .agreeingToPolicies)
    }

    @Test
    func `로그인 성공은 직군 입력 필요 여부를 signedIn으로 위임한다`() async {
        let account = MainShellAccountUseCaseStub(signInResults: [.signedIn(uncuratedAccount)])
        let store = makeStore(account: account, state: consentCheckedState())

        await store.send(.input(.start)) {
            $0.phase = .signingIn
            $0.requestID = 1
        }
        await store.receive(.effect(.signInFinished(requestID: 1, result: .signedIn(uncuratedAccount)))) {
            $0.phase = .idle
        }
        await store.receive(.delegate(.signedIn(needsCuration: true)))
    }

    @Test
    func `로그인 취소는 실패 없이 취소 상태가 되고 signInCancelled를 보낸다`() async {
        let account = MainShellAccountUseCaseStub(signInResults: [.cancelled])
        let store = makeStore(account: account, state: consentCheckedState())

        await store.send(.input(.start)) {
            $0.phase = .signingIn
            $0.requestID = 1
        }
        await store.receive(.effect(.signInFinished(requestID: 1, result: .cancelled))) {
            $0.phase = .cancelled
        }
        await store.receive(.delegate(.signInCancelled))

        #expect(!store.state.isFailed)
        #expect(store.state.isCancelled)
    }

    @Test
    func `재시도 가능한 실패는 실패 상태가 되고 닫으면 대기 상태로 돌아간다`() async {
        let account = MainShellAccountUseCaseStub(signInResults: [.retryableFailure])
        let store = makeStore(account: account, state: consentCheckedState())

        await store.send(.input(.start)) {
            $0.phase = .signingIn
            $0.requestID = 1
        }
        await store.receive(.effect(.signInFinished(requestID: 1, result: .retryableFailure))) {
            $0.phase = .failed
        }

        #expect(store.state.isFailed)

        await store.send(.view(.failureDismissed)) {
            $0.phase = .idle
        }
    }

    @Test(arguments: [SignInFeature.Phase.cancelled, .failed])
    func `취소나 실패 뒤의 start는 로그인을 다시 시작한다`(phase: SignInFeature.Phase) async {
        let account = MainShellAccountUseCaseStub(signInResults: [.signedIn(curatedAccount)])
        var state = consentCheckedState()
        state.phase = phase
        let store = makeStore(account: account, state: state)

        await store.send(.input(.start)) {
            $0.phase = .signingIn
            $0.requestID = 1
        }
        await store.receive(.effect(.signInFinished(requestID: 1, result: .signedIn(curatedAccount)))) {
            $0.phase = .idle
        }
        await store.receive(.delegate(.signedIn(needsCuration: false)))
    }

    @Test(arguments: [SignInFeature.Phase.checkingConsent, .agreeingToPolicies, .signingIn])
    func `진행 중인 흐름에서는 start를 다시 받아도 로그인 요청을 추가로 보내지 않는다`(phase: SignInFeature.Phase) async {
        let account = MainShellAccountUseCaseStub(signInResults: [.signedIn(curatedAccount)])
        var state = consentCheckedState()
        state.phase = phase
        state.requestID = 1
        let store = makeStore(account: account, state: state)

        await store.send(.input(.start))

        #expect(await account.snapshot().signInMethods.isEmpty)
    }

    @Test
    func `request ID가 다르거나 로그인 중이 아니면 로그인 결과를 반영하지 않는다`() async {
        var state = consentCheckedState()
        state.phase = .signingIn
        state.requestID = 2
        let store = makeStore(account: MainShellAccountUseCaseStub(), state: state)

        await store.send(.effect(.signInFinished(requestID: 1, result: .signedIn(curatedAccount))))

        #expect(store.state.phase == .signingIn)

        var idleState = consentCheckedState()
        idleState.requestID = 1
        let idleStore = makeStore(account: MainShellAccountUseCaseStub(), state: idleState)

        await idleStore.send(.effect(.signInFinished(requestID: 1, result: .signedIn(curatedAccount))))

        #expect(idleStore.state.phase == .idle)
    }

    // MARK: Private

    private let curatedAccount = OnboardingTestFixture.signedInAccount(needsCuration: false)
    private let uncuratedAccount = OnboardingTestFixture.signedInAccount(needsCuration: true)

    private func consentCheckedState() -> SignInFeature.State {
        var state = SignInFeature.State()
        state.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legalAgreement.isStoredConsentValid = true
        return state
    }

    private func makeStore(
        account: MainShellAccountUseCaseStub,
        state: SignInFeature.State = SignInFeature.State(),
    ) -> TestStoreOf<SignInFeature> {
        TestStore(initialState: state) {
            SignInFeature(
                signIn: { await account.signIn(with: $0) },
                policyConsentStatus: { try await account.policyConsentStatus() },
                consent: { try await account.consent(to: $0) },
            )
        }
    }

}
