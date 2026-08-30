import DomainAuthentication
import DomainMember
import Testing

@testable import Feature

@Suite("OnboardingGuideFeature tutorial·법적 동의·Apple 로그인")
struct OnboardingGuideFeatureTests {

    @Test
    func `tutorial 페이지 변경은 현재 페이지 값만 갱신한다`() async {
        var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
        state.screen = .tutorial(page: 1)
        let store = makeOnboardingGuideStore(state: state)

        await store.send(.view(.tutorialPageChanged(2))) {
            $0.screen = .tutorial(page: 2)
        }
    }

    @Test
    func `tutorial 진입 시 필수 문서와 저장 동의 기록을 한 번만 불러온다`() async {
        let policyConsent = PolicyConsentUseCaseMock(
            requiredDocuments: OnboardingTestFixture.requiredDocuments,
            storedConsentRecords: [],
        )
        var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
        state.screen = .tutorial(page: 1)
        let store = makeOnboardingGuideStore(policyConsent: policyConsent, state: state)

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
    func `저장 동의가 유효하면 legalAgreement 없이 바로 Apple 로그인을 시작하고 needsCuration을 그대로 위임한다`() async {
        var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
        state.screen = .tutorial(page: 3)
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legal.storedConsentRecords = OnboardingTestFixture.validConsentRecords
        let signIn = SignInUseCaseMock(results: [.success(OnboardingTestFixture.authenticatedUser, needsCuration: false)])
        let store = makeOnboardingGuideStore(signIn: signIn, state: state)

        await store.send(.view(.appleSignInTapped)) {
            $0.screen = .tutorial(page: 3)
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
            $0.authentication = .idle
        }
        await store.receive(.delegate(.signInSucceeded(needsCuration: false)))

        #expect(await signIn.snapshot() == [.apple])
    }

    @Test
    func `저장 동의가 유효하지 않으면 로그인 성공 뒤 legalAgreement 단계로 이동하고 선택을 초기화한다`() async {
        var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
        state.screen = .tutorial(page: 3)
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legal.selectedDocumentIDs = [OnboardingTestFixture.privacyPolicy.identifier]
        let signIn = SignInUseCaseMock(results: [.success(OnboardingTestFixture.authenticatedUser, needsCuration: true)])
        let store = makeOnboardingGuideStore(signIn: signIn, state: state)

        await store.send(.view(.appleSignInTapped)) {
            $0.authentication = .signingIn
            $0.requestID = 1
        }
        await store.receive(
            .effect(
                .signInFinished(
                    requestID: 1,
                    result: .success(OnboardingTestFixture.authenticatedUser, needsCuration: true),
                )
            )
        ) {
            $0.authentication = .idle
            $0.screen = .legalAgreement
            $0.legal.selectedDocumentIDs = []
            $0.pendingSignInNeedsCuration = true
        }

        #expect(await signIn.snapshot() == [.apple])
    }

    @Test
    func `필수 문서를 모두 선택하고 계속하기를 누르면 동의를 저장하고 대기 중인 needsCuration을 위임한다`() async {
        var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
        state.screen = .legalAgreement
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.pendingSignInNeedsCuration = true
        let policyConsent = PolicyConsentUseCaseMock(requiredDocuments: OnboardingTestFixture.requiredDocuments)
        let store = makeOnboardingGuideStore(policyConsent: policyConsent, state: state)
        store.exhaustivity = .off

        await store.send(.view(.legalDocumentToggled(documentID: OnboardingTestFixture.privacyPolicy.identifier)))
        await store.send(.view(.legalDocumentToggled(documentID: OnboardingTestFixture.termsOfService.identifier)))
        #expect(store.state.legal.canContinue)

        await store.send(.view(.legalContinueTapped))
        #expect(store.state.screen == .tutorial(page: 3))
        #expect(store.state.pendingSignInNeedsCuration == nil)

        await store.receive(.delegate(.signInSucceeded(needsCuration: true)))

        let snapshot = await policyConsent.snapshot()
        #expect(snapshot.savedRecords.count == 1)
        #expect(Set(snapshot.savedRecords[0].map(\.documentIdentifier)) ==
            Set(OnboardingTestFixture.requiredDocuments.map(\.identifier)))
    }

    @Test
    func `일부만 선택하면 계속하기가 비활성 상태로 유지되고 저장·로그인을 호출하지 않는다`() async {
        var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
        state.screen = .legalAgreement
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        let policyConsent = PolicyConsentUseCaseMock(requiredDocuments: OnboardingTestFixture.requiredDocuments)
        let signIn = SignInUseCaseMock()
        let store = makeOnboardingGuideStore(signIn: signIn, policyConsent: policyConsent, state: state)

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
        var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
        state.screen = .legalAgreement
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legal.selectedDocumentIDs = [OnboardingTestFixture.privacyPolicy.identifier]
        let policyConsent = PolicyConsentUseCaseMock(requiredDocuments: OnboardingTestFixture.requiredDocuments)
        let signIn = SignInUseCaseMock()
        let store = makeOnboardingGuideStore(signIn: signIn, policyConsent: policyConsent, state: state)

        await store.send(.view(.legalSheetCancelTapped)) {
            $0.screen = .tutorial(page: 3)
            $0.legal.selectedDocumentIDs = []
        }

        #expect(await signIn.snapshot().isEmpty)
        #expect(await policyConsent.snapshot().savedRecords.isEmpty)
    }

    @Test
    func `약관 링크를 탭하면 해당 문서를 fullsheet로 표시하고 닫으면 해제한다`() async {
        var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
        state.screen = .legalAgreement
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        let store = makeOnboardingGuideStore(state: state)
        let documentID = OnboardingTestFixture.privacyPolicy.identifier

        await store.send(.view(.legalDocumentLinkTapped(documentID: documentID))) {
            $0.legal.presentedDocumentID = documentID
        }
        #expect(store.state.legal.presentedDocument == OnboardingTestFixture.privacyPolicy)

        await store.send(.view(.legalDocumentSheetDismissed)) {
            $0.legal.presentedDocumentID = nil
        }
    }

    @Test
    func `로그인 진행 중 중복 탭은 추가 로그인 호출을 만들지 않는다`() async {
        var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
        state.screen = .tutorial(page: 3)
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legal.storedConsentRecords = OnboardingTestFixture.validConsentRecords
        let signIn = SignInUseCaseMock(results: [.retryableFailure])
        let store = makeOnboardingGuideStore(signIn: signIn, state: state)

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
        var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
        state.screen = .tutorial(page: 3)
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legal.storedConsentRecords = OnboardingTestFixture.validConsentRecords
        let signIn = SignInUseCaseMock(results: [.cancelled])
        let store = makeOnboardingGuideStore(signIn: signIn, state: state)

        await store.send(.view(.appleSignInTapped)) {
            $0.authentication = .signingIn
            $0.requestID = 1
        }
        await store.receive(.effect(.signInFinished(requestID: 1, result: .cancelled))) {
            $0.authentication = .cancelled
        }
    }

    @Test
    func `deletesCompletedAccountOnSignIn이 true면 needsCuration false 응답을 받은 뒤 회원탈퇴하고 자동으로 재로그인한다`() async {
        var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
        state.screen = .tutorial(page: 3)
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legal.storedConsentRecords = OnboardingTestFixture.validConsentRecords
        let signIn = SignInUseCaseMock(results: [
            .success(OnboardingTestFixture.authenticatedUser, needsCuration: false),
            .success(OnboardingTestFixture.authenticatedUser, needsCuration: true),
        ])
        let deleteMemberAccount = DeleteMemberAccountUseCaseMock()
        let store = makeOnboardingGuideStore(
            signIn: signIn,
            deleteMemberAccount: deleteMemberAccount,
            deletesCompletedAccountOnSignIn: true,
            state: state,
        )

        await store.send(.view(.appleSignInTapped)) {
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
            $0.hasAttemptedCompletedAccountReset = true
            $0.requestID = 2
        }
        await store.receive(
            .effect(
                .signInFinished(
                    requestID: 2,
                    result: .success(OnboardingTestFixture.authenticatedUser, needsCuration: true),
                )
            )
        ) {
            $0.authentication = .idle
        }
        await store.receive(.delegate(.signInSucceeded(needsCuration: true)))

        #expect(await signIn.snapshot() == [.apple, .apple])
        #expect(await deleteMemberAccount.snapshot() == 1)
    }

    @Test
    func `deletesCompletedAccountOnSignIn이 true여도 재시도가 다시 needsCuration false를 받으면 더 이상 반복하지 않는다`() async {
        var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
        state.screen = .tutorial(page: 3)
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legal.storedConsentRecords = OnboardingTestFixture.validConsentRecords
        let signIn = SignInUseCaseMock(results: [
            .success(OnboardingTestFixture.authenticatedUser, needsCuration: false),
            .success(OnboardingTestFixture.authenticatedUser, needsCuration: false),
        ])
        let deleteMemberAccount = DeleteMemberAccountUseCaseMock()
        let store = makeOnboardingGuideStore(
            signIn: signIn,
            deleteMemberAccount: deleteMemberAccount,
            deletesCompletedAccountOnSignIn: true,
            state: state,
        )

        await store.send(.view(.appleSignInTapped)) {
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
            $0.hasAttemptedCompletedAccountReset = true
            $0.requestID = 2
        }
        await store.receive(
            .effect(
                .signInFinished(
                    requestID: 2,
                    result: .success(OnboardingTestFixture.authenticatedUser, needsCuration: false),
                )
            )
        ) {
            $0.authentication = .idle
        }
        await store.receive(.delegate(.signInSucceeded(needsCuration: false)))

        #expect(await signIn.snapshot() == [.apple, .apple])
        #expect(await deleteMemberAccount.snapshot() == 1)
    }

    @Test
    func `현재 requestID와 다른 로그인 응답은 상태를 바꾸지 않는다`() async {
        var state = OnboardingGuideFeature.State(bundleVersion: "1.0.0")
        state.screen = .tutorial(page: 3)
        state.legal.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.legal.storedConsentRecords = OnboardingTestFixture.validConsentRecords
        let signIn = SignInUseCaseMock(results: [.cancelled])
        let store = makeOnboardingGuideStore(signIn: signIn, state: state)

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
