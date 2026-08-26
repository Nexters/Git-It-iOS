import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation
@testable import Feature

func makeOnboardingStore(
    restoreSession: RestoreSessionUseCaseMock = RestoreSessionUseCaseMock(),
    signIn: SignInUseCaseMock = SignInUseCaseMock(),
    signOut: SignOutUseCaseMock = SignOutUseCaseMock(),
    fetchMemberProfile: FetchMemberProfileUseCaseMock = FetchMemberProfileUseCaseMock(),
    completeCuration: CompleteCurationUseCaseMock = CompleteCurationUseCaseMock(),
    policyConsent: PolicyConsentUseCaseMock = PolicyConsentUseCaseMock(),
    state: OnboardingFeature.State = OnboardingFeature.State(bundleVersion: "1.0.0"),
) -> TestStoreOf<OnboardingFeature> {
    TestStore(initialState: state) {
        OnboardingFeature(
            restoreSession: restoreSession,
            signIn: signIn,
            signOut: signOut,
            fetchMemberProfile: fetchMemberProfile,
            completeCuration: completeCuration,
            policyConsent: policyConsent,
        )
    }
}
