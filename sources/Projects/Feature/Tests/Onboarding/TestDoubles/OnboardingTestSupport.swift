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

func makeOnboardingGuideStore(
    signIn: SignInUseCaseMock = SignInUseCaseMock(),
    policyConsent: PolicyConsentUseCaseMock = PolicyConsentUseCaseMock(),
    deleteMemberAccount: DeleteMemberAccountUseCaseMock = DeleteMemberAccountUseCaseMock(),
    deletesCompletedAccountOnSignIn: Bool = false,
    state: OnboardingGuideFeature.State = OnboardingGuideFeature.State(bundleVersion: "1.0.0"),
) -> TestStoreOf<OnboardingGuideFeature> {
    TestStore(initialState: state) {
        OnboardingGuideFeature(
            signIn: signIn,
            policyConsent: policyConsent,
            deleteMemberAccount: deleteMemberAccount,
            deletesCompletedAccountOnSignIn: deletesCompletedAccountOnSignIn,
        )
    }
}

func makeCurationStore(
    signOut: SignOutUseCaseMock = SignOutUseCaseMock(),
    completeCuration: CompleteCurationUseCaseMock = CompleteCurationUseCaseMock(),
    state: CurationFeature.State = CurationFeature.State(),
) -> TestStoreOf<CurationFeature> {
    TestStore(initialState: state) {
        CurationFeature(
            signOut: signOut,
            completeCuration: completeCuration,
        )
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
