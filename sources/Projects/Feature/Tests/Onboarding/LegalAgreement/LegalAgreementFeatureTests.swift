import DomainMember
import Testing

@testable import Feature

@Suite("LegalAgreementFeature")
struct LegalAgreementFeatureTests {

    @Test
    func `load 입력은 필수 문서와 저장 동의 기록을 한 번만 불러온다`() async {
        let policyConsent = PolicyConsentUseCaseMock(
            requiredDocuments: OnboardingTestFixture.requiredDocuments,
            storedConsentRecords: [],
        )
        let store = makeLegalAgreementStore(policyConsent: policyConsent)

        await store.send(.input(.load))
        await store.receive(
            .effect(
                .documentsLoaded(
                    requiredDocuments: OnboardingTestFixture.requiredDocuments,
                    storedConsentRecords: [],
                )
            )
        ) {
            $0.requiredDocuments = OnboardingTestFixture.requiredDocuments
        }

        await store.send(.input(.load))

        #expect(await policyConsent.snapshot().requiredDocumentsCallCount == 1)
    }

    @Test
    func `prepare 입력은 대기 중인 needsCuration을 보관하고 선택을 초기화한다`() async {
        var state = LegalAgreementFeature.State()
        state.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.selectedDocumentIDs = [OnboardingTestFixture.privacyPolicy.identifier]
        let store = makeLegalAgreementStore(state: state)

        await store.send(.input(.prepare(needsCuration: true))) {
            $0.pendingNeedsCuration = true
            $0.selectedDocumentIDs = []
        }
    }

    @Test
    func `필수 문서를 모두 선택하고 계속하기를 누르면 동의를 저장하고 대기 중인 needsCuration을 위임한다`() async {
        var state = LegalAgreementFeature.State()
        state.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.pendingNeedsCuration = true
        let policyConsent = PolicyConsentUseCaseMock(requiredDocuments: OnboardingTestFixture.requiredDocuments)
        let store = makeLegalAgreementStore(policyConsent: policyConsent, state: state)
        store.exhaustivity = .off

        await store.send(.view(.documentToggled(documentID: OnboardingTestFixture.privacyPolicy.identifier)))
        await store.send(.view(.documentToggled(documentID: OnboardingTestFixture.termsOfService.identifier)))
        #expect(store.state.canContinue)
        #expect(store.state.isAllSelected)

        await store.send(.view(.continueTapped))
        #expect(store.state.pendingNeedsCuration == nil)

        await store.receive(.delegate(.consentCompleted(needsCuration: true)))

        let snapshot = await policyConsent.snapshot()
        #expect(snapshot.savedRecords.count == 1)
        #expect(Set(snapshot.savedRecords[0].map(\.documentIdentifier)) ==
            Set(OnboardingTestFixture.requiredDocuments.map(\.identifier)))
    }

    @Test
    func `전체 선택 토글은 모든 문서를 선택하고 다시 누르면 해제한다`() async {
        var state = LegalAgreementFeature.State()
        state.requiredDocuments = OnboardingTestFixture.requiredDocuments
        let store = makeLegalAgreementStore(state: state)

        await store.send(.view(.allDocumentsToggled)) {
            $0.selectedDocumentIDs = Set(OnboardingTestFixture.requiredDocuments.map(\.identifier))
        }
        await store.send(.view(.allDocumentsToggled)) {
            $0.selectedDocumentIDs = []
        }
    }

    @Test
    func `일부만 선택하면 계속하기가 비활성 상태로 유지되고 저장을 호출하지 않는다`() async {
        var state = LegalAgreementFeature.State()
        state.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.pendingNeedsCuration = true
        let policyConsent = PolicyConsentUseCaseMock(requiredDocuments: OnboardingTestFixture.requiredDocuments)
        let store = makeLegalAgreementStore(policyConsent: policyConsent, state: state)

        await store.send(.view(.documentToggled(documentID: OnboardingTestFixture.privacyPolicy.identifier))) {
            $0.selectedDocumentIDs = [OnboardingTestFixture.privacyPolicy.identifier]
        }
        #expect(!store.state.canContinue)

        await store.send(.view(.continueTapped))

        #expect(await policyConsent.snapshot().savedRecords.isEmpty)
    }

    @Test
    func `취소는 선택을 초기화하고 저장 없이 cancelled를 위임한다`() async {
        var state = LegalAgreementFeature.State()
        state.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.selectedDocumentIDs = [OnboardingTestFixture.privacyPolicy.identifier]
        state.pendingNeedsCuration = true
        let policyConsent = PolicyConsentUseCaseMock(requiredDocuments: OnboardingTestFixture.requiredDocuments)
        let store = makeLegalAgreementStore(policyConsent: policyConsent, state: state)

        await store.send(.view(.cancelTapped)) {
            $0.selectedDocumentIDs = []
            $0.pendingNeedsCuration = nil
        }
        await store.receive(.delegate(.cancelled))

        #expect(await policyConsent.snapshot().savedRecords.isEmpty)
    }

    @Test
    func `약관 링크를 탭하면 해당 문서를 fullsheet로 표시하고 닫으면 해제한다`() async {
        var state = LegalAgreementFeature.State()
        state.requiredDocuments = OnboardingTestFixture.requiredDocuments
        let store = makeLegalAgreementStore(state: state)
        let documentID = OnboardingTestFixture.privacyPolicy.identifier

        await store.send(.view(.documentLinkTapped(documentID: documentID))) {
            $0.presentedDocumentID = documentID
        }
        #expect(store.state.presentedDocument == OnboardingTestFixture.privacyPolicy)

        await store.send(.view(.documentSheetDismissed)) {
            $0.presentedDocumentID = nil
        }
    }

    @Test
    func `저장된 동의 기록이 필수 문서를 모두 덮으면 유효한 동의로 판단한다`() {
        var state = LegalAgreementFeature.State()
        state.requiredDocuments = OnboardingTestFixture.requiredDocuments
        state.storedConsentRecords = OnboardingTestFixture.validConsentRecords
        let store = makeLegalAgreementStore(state: state)

        #expect(store.state.isStoredConsentValid)
    }

}
