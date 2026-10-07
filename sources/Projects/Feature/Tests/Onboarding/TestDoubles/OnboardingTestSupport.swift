import ComposableArchitecture
import DomainAuthentication
import DomainMember
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
            restoreSession: restoreSession,
            fetchMemberProfile: fetchMemberProfile,
            signOut: signOut,
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
            signIn: signIn,
            deleteMemberAccount: deleteMemberAccount,
            deletesCompletedAccountOnSignIn: deletesCompletedAccountOnSignIn,
        )
    }
}

func makeLegalAgreementStore(
    policyConsent: PolicyConsentUseCaseMock = PolicyConsentUseCaseMock(),
    state: LegalAgreementFeature.State = LegalAgreementFeature.State(),
) -> TestStoreOf<LegalAgreementFeature> {
    TestStore(initialState: state) {
        LegalAgreementFeature(policyConsent: policyConsent)
    }
}

func makePositionSelectionStore(
    signOut: SignOutUseCaseMock = SignOutUseCaseMock(),
    state: PositionSelectionFeature.State = PositionSelectionFeature.State(),
) -> TestStoreOf<PositionSelectionFeature> {
    TestStore(initialState: state) {
        PositionSelectionFeature(signOut: signOut)
    }
}

func makeCareerSelectionStore(
    completeCuration: CompleteCurationUseCaseMock = CompleteCurationUseCaseMock(),
    state: CareerSelectionFeature.State = CareerSelectionFeature.State(),
) -> TestStoreOf<CareerSelectionFeature> {
    TestStore(initialState: state) {
        CareerSelectionFeature(completeCuration: completeCuration)
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
    completeCuration: CompleteCurationUseCaseMock = CompleteCurationUseCaseMock(),
    deleteMemberAccount: DeleteMemberAccountUseCaseMock = DeleteMemberAccountUseCaseMock(),
    deletesCompletedAccountOnSignIn: Bool = false,
    state: OnboardingRouterFeature.State = OnboardingRouterFeature.State(startingAt: .guide, bundleVersion: "1.0.0"),
) -> TestStoreOf<OnboardingRouterFeature> {
    TestStore(initialState: state) {
        OnboardingRouterFeature(
            signIn: signIn,
            signOut: signOut,
            policyConsent: policyConsent,
            completeCuration: completeCuration,
            deleteMemberAccount: deleteMemberAccount,
            deletesCompletedAccountOnSignIn: deletesCompletedAccountOnSignIn,
        )
    }
}
