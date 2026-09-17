import ComposableArchitecture
import DomainAccount
import DomainUserInfo
import Foundation
@testable import Feature

func makeAppEntryStore(
    restoreSession: RestoreSessionUseCaseMock = RestoreSessionUseCaseMock(),
    fetchMemberProfile: FetchMemberProfileUseCaseMock = FetchMemberProfileUseCaseMock(),
    signOut: SignOutUseCaseMock = SignOutUseCaseMock(),
    state: AppEntryFeature.State = AppEntryFeature.State(),
) -> TestStoreOf<AppEntryFeature> {
    TestStore(initialState: state) {
        AppEntryFeature(
            restoreSignIn: restoreSession.restoreSignIn,
            curation: fetchMemberProfile.curation,
            signOut: signOut.signOut,
        )
    }
}

func makeTutorialStore(
    signIn: SignInUseCaseMock = SignInUseCaseMock(),
    deleteMemberAccount: DeleteMemberAccountUseCaseMock = DeleteMemberAccountUseCaseMock(),
    deletesCompletedAccountOnSignIn: Bool = false,
    state: TutorialFeature.State = TutorialFeature.State(bundleVersion: "1.0.0"),
) -> TestStoreOf<TutorialFeature> {
    TestStore(initialState: state) {
        TutorialFeature(
            signIn: signIn.signIn,
            withdraw: deleteMemberAccount.withdraw,
            deletesCompletedAccountOnSignIn: deletesCompletedAccountOnSignIn,
        )
    }
}

func makeLegalAgreementStore(
    policyConsent: PolicyConsentUseCaseMock = PolicyConsentUseCaseMock(),
    state: LegalAgreementFeature.State = LegalAgreementFeature.State(),
) -> TestStoreOf<LegalAgreementFeature> {
    TestStore(initialState: state) {
        LegalAgreementFeature(
            policyConsentStatus: policyConsent.policyConsentStatus,
            consent: policyConsent.consent,
        )
    }
}

func makePositionSelectionStore(
    signOut: SignOutUseCaseMock = SignOutUseCaseMock(),
    state: PositionSelectionFeature.State = PositionSelectionFeature.State(),
) -> TestStoreOf<PositionSelectionFeature> {
    TestStore(initialState: state) {
        PositionSelectionFeature(signOut: signOut.signOut)
    }
}

func makeCareerSelectionStore(
    completeCuration: CompleteCurationUseCaseMock = CompleteCurationUseCaseMock(),
    state: CareerSelectionFeature.State = CareerSelectionFeature.State(),
) -> TestStoreOf<CareerSelectionFeature> {
    TestStore(initialState: state) {
        CareerSelectionFeature(updateCuration: completeCuration.updateCuration)
    }
}

func makeOnboardingExitStore(
    state: OnboardingExitFeature.State = OnboardingExitFeature.State()
) -> TestStoreOf<OnboardingExitFeature> {
    TestStore(initialState: state) {
        OnboardingExitFeature()
    }
}

func makeOnboardingRouterStore(
    signIn: SignInUseCaseMock = SignInUseCaseMock(),
    signOut: SignOutUseCaseMock = SignOutUseCaseMock(),
    policyConsent: PolicyConsentUseCaseMock = PolicyConsentUseCaseMock(),
    memberAccount: MemberAccountUseCaseMock = MemberAccountUseCaseMock(),
    deleteMemberAccount: DeleteMemberAccountUseCaseMock = DeleteMemberAccountUseCaseMock(),
    deletesCompletedAccountOnSignIn: Bool = false,
    state: OnboardingRouterFeature.State = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0"),
) -> TestStoreOf<OnboardingRouterFeature> {
    TestStore(initialState: state) {
        OnboardingRouterFeature(
            signIn: signIn.signIn,
            signOut: signOut.signOut,
            policyConsentStatus: policyConsent.policyConsentStatus,
            consent: policyConsent.consent,
            updateCuration: { try await memberAccount.updateCuration($0) },
            withdraw: deleteMemberAccount.withdraw,
            deletesCompletedAccountOnSignIn: deletesCompletedAccountOnSignIn,
        )
    }
}
