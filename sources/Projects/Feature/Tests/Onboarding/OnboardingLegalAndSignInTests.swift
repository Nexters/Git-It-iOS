import DomainAuthentication
import DomainMember
import Testing

@testable import Feature

@Suite("OnboardingFeature tutorial·법적 동의·Apple 로그인")
struct OnboardingLegalAndSignInTests {

    @Test
    func `tutorial 페이지 변경은 현재 페이지 값만 갱신한다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .tutorial(page: 1)
        let store = makeOnboardingStore(state: state)

        await store.send(.view(.tutorialPageChanged(2))) {
            $0.phase = .tutorial(page: 2)
        }
    }

    @Test
    func `tutorial 진입 시 필수 문서와 저장 동의 기록을 한 번만 불러온다`() async {
        let policyConsent = PolicyConsentUseCaseMock(
            requiredDocuments: OnboardingTestFixture.requiredDocuments,
            storedConsentRecords: [],
        )
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .tutorial(page: 1)
        let store = makeOnboardingStore(policyConsent: policyConsent, state: state)

        await store.send(.view(.tutorialAppeared))
        await store.receive(
            .effect(
                .legalDocumentsLoaded(
                    requiredDocuments: OnboardingTestFixture.requiredDocuments,
                    storedConsentRecords: [],
                )
            )
        ) {
            $0.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        }

        await store.send(.view(.tutorialAppeared))

        #expect(await policyConsent.snapshot().requiredDocumentsCallCount == 1)
    }

    @Test
    func `저장 동의가 유효하면 legalAgreement 없이 바로 Apple 로그인을 시작한다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .tutorial(page: 3)
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legal.storedConsentRecords = OnboardingTestFixture.validConsentRecords
        let signIn = SignInUseCaseMock(results: [.success(OnboardingTestFixture.authenticatedUser, needsCuration: false)])
        let store = makeOnboardingStore(signIn: signIn, state: state)

        await store.send(.view(.appleSignInTapped)) {
            $0.phase = .tutorial(page: 3)
            $0.authentication = .signingIn
            $0.requestID = 1
        }
        await store.receive(
            .effect(
                .signInFinished(
                    requestID: 1,
                    result: .success(OnboardingTestFixture.authenticatedUser, needsCuration: false),
                )
            )
        ) {
            $0.authentication = .success
            $0.phase = .completing
        }
        await store.receive(.delegate(.mainShellRequested))

        #expect(await signIn.snapshot() == [.apple])
    }

    @Test
    func `저장 동의가 유효하지 않으면 legalAgreement 단계로 이동하고 선택을 초기화한다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .tutorial(page: 3)
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legal.selectedDocumentIDs = [OnboardingTestFixture.privacyPolicy.identifier]
        let signIn = SignInUseCaseMock()
        let store = makeOnboardingStore(signIn: signIn, state: state)

        await store.send(.view(.appleSignInTapped)) {
            $0.phase = .legalAgreement
            $0.legal.selectedDocumentIDs = []
        }

        #expect(await signIn.snapshot().isEmpty)
    }

    @Test
    func `필수 문서를 모두 선택하고 계속하기를 누르면 동의를 저장하고 로그인을 시작한다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .legalAgreement
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        let policyConsent = PolicyConsentUseCaseMock(requiredDocuments: OnboardingTestFixture.requiredDocuments)
        let signIn = SignInUseCaseMock(results: [.success(OnboardingTestFixture.authenticatedUser, needsCuration: true)])
        let store = makeOnboardingStore(signIn: signIn, policyConsent: policyConsent, state: state)
        // 저장 기록의 acceptedAt은 저장 시각(Date())이라 결정적으로 단언할 수 없으므로 이 테스트만
        // 비 exhaustive 모드로 전환하고 나머지 필드는 #expect로 개별 검증한다.
        store.exhaustivity = .off

        await store.send(.view(.legalDocumentToggled(documentID: OnboardingTestFixture.privacyPolicy.identifier)))
        await store.send(.view(.legalDocumentToggled(documentID: OnboardingTestFixture.termsOfService.identifier)))
        #expect(store.state.legal.canContinue)

        await store.send(.view(.legalContinueTapped))
        #expect(store.state.phase == .tutorial(page: 3))
        #expect(store.state.authentication == .signingIn)

        await store.receive(
            .effect(
                .signInFinished(
                    requestID: 1,
                    result: .success(OnboardingTestFixture.authenticatedUser, needsCuration: true),
                )
            )
        )
        #expect(store.state.authentication == .success)
        #expect(store.state.phase == .position)

        let snapshot = await policyConsent.snapshot()
        #expect(snapshot.savedRecords.count == 1)
        #expect(Set(snapshot.savedRecords[0].map(\.documentIdentifier)) == Set(OnboardingTestFixture.requiredDocuments.map(\.identifier)))
    }

    @Test
    func `일부만 선택하면 계속하기가 비활성 상태로 유지되고 저장·로그인을 호출하지 않는다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .legalAgreement
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        let policyConsent = PolicyConsentUseCaseMock(requiredDocuments: OnboardingTestFixture.requiredDocuments)
        let signIn = SignInUseCaseMock()
        let store = makeOnboardingStore(signIn: signIn, policyConsent: policyConsent, state: state)

        await store.send(.view(.legalDocumentToggled(documentID: OnboardingTestFixture.privacyPolicy.identifier))) {
            $0.legal.selectedDocumentIDs = [OnboardingTestFixture.privacyPolicy.identifier]
        }
        #expect(!store.state.legal.canContinue)

        await store.send(.view(.legalContinueTapped))

        #expect(await signIn.snapshot().isEmpty)
        #expect(await policyConsent.snapshot().savedRecords.isEmpty)
    }

    @Test
    func `sheet 취소는 선택을 초기화하고 저장이나 로그인을 호출하지 않는다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .legalAgreement
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legal.selectedDocumentIDs = [OnboardingTestFixture.privacyPolicy.identifier]
        let policyConsent = PolicyConsentUseCaseMock(requiredDocuments: OnboardingTestFixture.requiredDocuments)
        let signIn = SignInUseCaseMock()
        let store = makeOnboardingStore(signIn: signIn, policyConsent: policyConsent, state: state)

        await store.send(.view(.legalSheetCancelTapped)) {
            $0.phase = .tutorial(page: 3)
            $0.legal.selectedDocumentIDs = []
        }

        #expect(await signIn.snapshot().isEmpty)
        #expect(await policyConsent.snapshot().savedRecords.isEmpty)
    }

    @Test
    func `외부 브라우저 열기 요청 실패는 문서별 오류를 표시하고 재시도로 복구한다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .legalAgreement
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        let store = makeOnboardingStore(state: state)
        let documentID = OnboardingTestFixture.privacyPolicy.identifier

        await store.send(.view(.legalDocumentLinkTapped(documentID: documentID))) {
            $0.legal.linkStatus[documentID] = .opening
        }
        await store.send(.view(.legalDocumentLinkOpenResult(documentID: documentID, success: false))) {
            $0.legal.linkStatus[documentID] = .openFailed
        }

        // 열기 요청 실패는 계속하기 가능 여부에 영향을 주지 않는다.
        #expect(!store.state.legal.canContinue)

        await store.send(.view(.legalDocumentLinkTapped(documentID: documentID))) {
            $0.legal.linkStatus[documentID] = .opening
        }
        await store.send(.view(.legalDocumentLinkOpenResult(documentID: documentID, success: true))) {
            $0.legal.linkStatus[documentID] = .idle
        }
    }

    @Test
    func `로그인 진행 중 중복 탭은 추가 로그인 호출을 만들지 않는다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .tutorial(page: 3)
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legal.storedConsentRecords = OnboardingTestFixture.validConsentRecords
        let signIn = SignInUseCaseMock(results: [.retryableFailure])
        let store = makeOnboardingStore(signIn: signIn, state: state)

        await store.send(.view(.appleSignInTapped)) {
            $0.authentication = .signingIn
            $0.requestID = 1
        }
        await store.send(.view(.appleSignInTapped))
        await store.receive(.effect(.signInFinished(requestID: 1, result: .retryableFailure))) {
            $0.authentication = .retryableFailure
        }

        #expect(await signIn.snapshot() == [.apple])
    }

    @Test
    func `Apple 인증 취소는 재시도 오류와 구분되는 cancelled 상태로 남는다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .tutorial(page: 3)
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legal.storedConsentRecords = OnboardingTestFixture.validConsentRecords
        let signIn = SignInUseCaseMock(results: [.cancelled])
        let store = makeOnboardingStore(signIn: signIn, state: state)

        await store.send(.view(.appleSignInTapped)) {
            $0.authentication = .signingIn
            $0.requestID = 1
        }
        await store.receive(.effect(.signInFinished(requestID: 1, result: .cancelled))) {
            $0.authentication = .cancelled
        }
    }

    @Test
    func `현재 requestID와 다른 로그인 응답은 상태를 바꾸지 않는다`() async {
        var state = OnboardingFeature.State(bundleVersion: "1.0.0")
        state.phase = .tutorial(page: 3)
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legal.storedConsentRecords = OnboardingTestFixture.validConsentRecords
        let signIn = SignInUseCaseMock(results: [.cancelled])
        let store = makeOnboardingStore(signIn: signIn, state: state)

        await store.send(.view(.appleSignInTapped)) {
            $0.authentication = .signingIn
            $0.requestID = 1
        }
        await store.send(.effect(.signInFinished(requestID: 999, result: .retryableFailure)))
        await store.receive(.effect(.signInFinished(requestID: 1, result: .cancelled))) {
            $0.authentication = .cancelled
        }
    }

}
