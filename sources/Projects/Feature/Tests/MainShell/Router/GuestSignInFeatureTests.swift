import ComposableArchitecture
import DomainAccount
import Testing

@testable import Feature

@MainActor
@Suite("GuestSignInFeature")
struct GuestSignInFeatureTests {

    // MARK: Internal

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
    func `약관 동의가 없으면 약관 단계로 가고 동의를 마친 뒤 로그인한다`() async {
        let account = MainShellAccountUseCaseStub(
            signInResults: [.signedIn(curatedAccount)],
            consentStatus: OnboardingTestFixture.pendingConsentStatus,
        )
        let store = makeStore(account: account)
        let documentIDs = Set(OnboardingTestFixture.requiredDocuments.map(\.id))

        await store.send(.input(.start)) {
            $0.phase = .checkingConsent
        }
        await store.receive(.legalAgreement(.input(.load)))
        await store.receive(.legalAgreement(.effect(.statusLoaded(
            requiredDocuments: OnboardingTestFixture.requiredDocuments,
            isStoredConsentValid: false,
        )))) {
            $0.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
            $0.phase = .agreeingToPolicies
        }
        await store.receive(.legalAgreement(.input(.prepare)))

        #expect(await account.snapshot().signInMethods.isEmpty)

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
    func `약관 동의를 취소하면 로그인 없이 대기 상태로 돌아간다`() async {
        let account = MainShellAccountUseCaseStub()
        var state = GuestSignInFeature.State()
        state.phase = .agreeingToPolicies
        state.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
        let store = makeStore(account: account, state: state)

        await store.send(.view(.legalAgreementDismissed))
        await store.receive(.legalAgreement(.view(.cancelTapped)))
        await store.receive(.legalAgreement(.delegate(.cancelled))) {
            $0.phase = .idle
        }

        #expect(await account.snapshot().signInMethods.isEmpty)
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
    func `로그인 취소는 실패 알럿 없이 대기 상태로 돌아간다`() async {
        let account = MainShellAccountUseCaseStub(signInResults: [.cancelled])
        let store = makeStore(account: account, state: consentCheckedState())

        await store.send(.input(.start)) {
            $0.phase = .signingIn
            $0.requestID = 1
        }
        await store.receive(.effect(.signInFinished(requestID: 1, result: .cancelled))) {
            $0.phase = .idle
        }

        #expect(!store.state.isFailureAlertPresented)
    }

    @Test
    func `재시도 가능한 실패는 실패 알럿을 띄우고 닫으면 대기 상태로 돌아간다`() async {
        let account = MainShellAccountUseCaseStub(signInResults: [.retryableFailure])
        let store = makeStore(account: account, state: consentCheckedState())

        await store.send(.input(.start)) {
            $0.phase = .signingIn
            $0.requestID = 1
        }
        await store.receive(.effect(.signInFinished(requestID: 1, result: .retryableFailure))) {
            $0.phase = .failed
        }

        #expect(store.state.isFailureAlertPresented)

        await store.send(.view(.failureDismissed)) {
            $0.phase = .idle
        }
    }

    @Test
    func `로그인 진행 중 start를 다시 받아도 로그인 요청을 추가로 보내지 않는다`() async {
        let account = MainShellAccountUseCaseStub(signInResults: [.signedIn(curatedAccount)])
        var state = consentCheckedState()
        state.phase = .signingIn
        state.requestID = 1
        let store = makeStore(account: account, state: state)

        await store.send(.input(.start))

        #expect(await account.snapshot().signInMethods.isEmpty)
    }

    // MARK: Private

    private let curatedAccount = OnboardingTestFixture.signedInAccount(needsCuration: false)
    private let uncuratedAccount = OnboardingTestFixture.signedInAccount(needsCuration: true)

    private func consentCheckedState() -> GuestSignInFeature.State {
        var state = GuestSignInFeature.State()
        state.legalAgreement.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legalAgreement.isStoredConsentValid = true
        return state
    }

    private func makeStore(
        account: MainShellAccountUseCaseStub,
        state: GuestSignInFeature.State = GuestSignInFeature.State(),
    ) -> TestStoreOf<GuestSignInFeature> {
        TestStore(initialState: state) {
            GuestSignInFeature(
                signIn: { await account.signIn(with: $0) },
                policyConsentStatus: { try await account.policyConsentStatus() },
                consent: { try await account.consent(to: $0) },
            )
        }
    }

}
