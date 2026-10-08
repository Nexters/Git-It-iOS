import Testing

@testable import Feature

@MainActor
@Suite("LegalAgreementFeature")
struct LegalAgreementFeatureTests {

    @Test
    func `load 입력은 필수 문서와 저장 동의 충족 여부를 한 번만 불러온다`() async {
        let policyConsent = AccountUseCaseConsentMock(status: OnboardingTestFixture.pendingConsentStatus)
        let store = makeLegalAgreementStore(policyConsent: policyConsent)

        await store.send(.input(.load))
        await store.receive(
            .effect(
                .statusLoaded(
                    requiredDocuments: OnboardingTestFixture.requiredDocuments,
                    isStoredConsentValid: false,
                )
            )
        ) {
            $0.requiredDocuments = OnboardingTestFixture.requiredDocuments
        }

        await store.send(.input(.load))

        #expect(await policyConsent.snapshot().statusCallCount == 1)
    }

    @Test
    func `prepare 입력은 선택을 초기화한다`() async {
        var state = LegalAgreementFeature.State()
        state.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.selectedDocumentIDs = [OnboardingTestFixture.privacyPolicy.id]
        let store = makeLegalAgreementStore(state: state)

        await store.send(.input(.prepare)) {
            $0.selectedDocumentIDs = []
        }
    }

    @Test
    func `필수 문서를 모두 선택하고 계속하기를 누르면 동의를 저장하고 완료를 위임한다`() async {
        var state = LegalAgreementFeature.State()
        state.requiredDocuments = OnboardingTestFixture.requiredDocuments
        let policyConsent = AccountUseCaseConsentMock(status: OnboardingTestFixture.pendingConsentStatus)
        let store = makeLegalAgreementStore(
            policyConsent: policyConsent,
            state: state,
        )
        store.exhaustivity = .off

        await store.send(.view(.documentToggled(documentID: OnboardingTestFixture.privacyPolicy.id)))
        await store.send(.view(.documentToggled(documentID: OnboardingTestFixture.termsOfService.id)))
        #expect(store.state.canContinue)
        #expect(store.state.isAllSelected)

        await store.send(.view(.continueTapped))

        await store.receive(.delegate(.consentCompleted))

        let snapshot = await policyConsent.snapshot()
        #expect(snapshot.consentedDocumentIDs.count == 1)
        #expect(Set(snapshot.consentedDocumentIDs[0]) == Set(OnboardingTestFixture.requiredDocuments.map(\.id)))
        #expect(store.state.isStoredConsentValid)
    }

    @Test
    func `전체 선택 토글은 모든 문서를 선택하고 다시 누르면 해제한다`() async {
        var state = LegalAgreementFeature.State()
        state.requiredDocuments = OnboardingTestFixture.requiredDocuments
        let store = makeLegalAgreementStore(state: state)

        await store.send(.view(.allDocumentsToggled)) {
            $0.selectedDocumentIDs = Set(OnboardingTestFixture.requiredDocuments.map(\.id))
        }
        await store.send(.view(.allDocumentsToggled)) {
            $0.selectedDocumentIDs = []
        }
    }

    @Test
    func `일부만 선택하면 계속하기가 비활성 상태로 유지되고 저장을 호출하지 않는다`() async {
        var state = LegalAgreementFeature.State()
        state.requiredDocuments = OnboardingTestFixture.requiredDocuments
        let policyConsent = AccountUseCaseConsentMock(status: OnboardingTestFixture.pendingConsentStatus)
        let store = makeLegalAgreementStore(
            policyConsent: policyConsent,
            state: state,
        )

        await store.send(.view(.documentToggled(documentID: OnboardingTestFixture.privacyPolicy.id))) {
            $0.selectedDocumentIDs = [OnboardingTestFixture.privacyPolicy.id]
        }
        #expect(!store.state.canContinue)

        await store.send(.view(.continueTapped))

        #expect(await policyConsent.snapshot().consentedDocumentIDs.isEmpty)
    }

    @Test
    func `취소는 선택을 초기화하고 저장 없이 cancelled를 위임한다`() async {
        var state = LegalAgreementFeature.State()
        state.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.selectedDocumentIDs = [OnboardingTestFixture.privacyPolicy.id]
        let policyConsent = AccountUseCaseConsentMock(status: OnboardingTestFixture.pendingConsentStatus)
        let store = makeLegalAgreementStore(
            policyConsent: policyConsent,
            state: state,
        )

        await store.send(.view(.cancelTapped)) {
            $0.selectedDocumentIDs = []
        }
        await store.receive(.delegate(.cancelled))

        #expect(await policyConsent.snapshot().consentedDocumentIDs.isEmpty)
    }

    @Test
    func `약관 링크를 탭하면 해당 문서를 fullsheet로 표시하고 닫으면 해제한다`() async {
        var state = LegalAgreementFeature.State()
        state.requiredDocuments = OnboardingTestFixture.requiredDocuments
        let store = makeLegalAgreementStore(state: state)
        let documentID = OnboardingTestFixture.privacyPolicy.id

        await store.send(.view(.documentLinkTapped(documentID: documentID))) {
            $0.presentedDocumentID = documentID
        }
        #expect(store.state.presentedDocument == OnboardingTestFixture.privacyPolicy)

        await store.send(.view(.documentSheetDismissed)) {
            $0.presentedDocumentID = nil
        }
    }

    @Test
    func `저장된 동의가 필수 문서를 모두 덮으면 유효한 동의로 판단한다`() async {
        let policyConsent = AccountUseCaseConsentMock(status: OnboardingTestFixture.satisfiedConsentStatus)
        let store = makeLegalAgreementStore(policyConsent: policyConsent)

        await store.send(.input(.load))
        await store.receive(
            .effect(
                .statusLoaded(
                    requiredDocuments: OnboardingTestFixture.requiredDocuments,
                    isStoredConsentValid: true,
                )
            )
        ) {
            $0.requiredDocuments = OnboardingTestFixture.requiredDocuments
            $0.isStoredConsentValid = true
        }
    }

}
