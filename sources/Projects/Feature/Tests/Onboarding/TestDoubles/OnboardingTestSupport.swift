import ComposableArchitecture
import DomainAccount
import DomainUserInfo
import Foundation
@testable import Feature

@MainActor
func makeAppEntryStore(
    restoreSession: AccountUseCaseRestorationMock = AccountUseCaseRestorationMock(),
    fetchMemberProfile: UserInfoUseCaseProfileMock = UserInfoUseCaseProfileMock(),
    signOut: AccountUseCaseSignOutMock = AccountUseCaseSignOutMock(),
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

@MainActor
func makeTutorialStore(
    signIn: AccountUseCaseSignInMock = AccountUseCaseSignInMock(),
    policyConsent: AccountUseCaseConsentMock = AccountUseCaseConsentMock(),
    accountWithdrawal: AccountUseCaseWithdrawalMock = AccountUseCaseWithdrawalMock(),
    deletesCompletedAccountOnSignIn: Bool = false,
    state: TutorialFeature.State = TutorialFeature.State(bundleVersion: "1.0.0"),
) -> TestStoreOf<TutorialFeature> {
    TestStore(initialState: state) {
        TutorialFeature(
            signIn: signIn.signIn,
            policyConsentStatus: policyConsent.policyConsentStatus,
            consent: policyConsent.consent,
            withdraw: accountWithdrawal.withdraw,
            deletesCompletedAccountOnSignIn: deletesCompletedAccountOnSignIn,
        )
    }
}

@MainActor
func makeLegalAgreementStore(
    policyConsent: AccountUseCaseConsentMock = AccountUseCaseConsentMock(),
    state: LegalAgreementFeature.State = LegalAgreementFeature.State(),
) -> TestStoreOf<LegalAgreementFeature> {
    TestStore(initialState: state) {
        LegalAgreementFeature(
            policyConsentStatus: policyConsent.policyConsentStatus,
            consent: policyConsent.consent,
        )
    }
}

@MainActor
func makePositionSelectionStore(
    signOut: AccountUseCaseSignOutMock = AccountUseCaseSignOutMock(),
    state: PositionSelectionFeature.State = PositionSelectionFeature.State(),
) -> TestStoreOf<PositionSelectionFeature> {
    TestStore(initialState: state) {
        PositionSelectionFeature(signOut: signOut.signOut)
    }
}

@MainActor
func makeCareerSelectionStore(
    completeCuration: UserInfoUseCaseCurationMock = UserInfoUseCaseCurationMock(),
    state: CareerSelectionFeature.State = CareerSelectionFeature.State(),
) -> TestStoreOf<CareerSelectionFeature> {
    TestStore(initialState: state) {
        CareerSelectionFeature(updateCuration: completeCuration.updateCuration)
    }
}

@MainActor
func makeOnboardingExitStore(
    state: OnboardingExitFeature.State = OnboardingExitFeature.State()
) -> TestStoreOf<OnboardingExitFeature> {
    TestStore(initialState: state) {
        OnboardingExitFeature()
    }
}

@MainActor
func makeOnboardingRouterStore(
    signIn: AccountUseCaseSignInMock = AccountUseCaseSignInMock(),
    signOut: AccountUseCaseSignOutMock = AccountUseCaseSignOutMock(),
    policyConsent: AccountUseCaseConsentMock = AccountUseCaseConsentMock(),
    userInfo: UserInfoUseCaseMock = UserInfoUseCaseMock(),
    accountWithdrawal: AccountUseCaseWithdrawalMock = AccountUseCaseWithdrawalMock(),
    deletesCompletedAccountOnSignIn: Bool = false,
    state: OnboardingRouterFeature.State = OnboardingRouterFeature.State(
        startingAt: .guide,
        bundleVersion: "1.0.0",
    ),
) -> TestStoreOf<OnboardingRouterFeature> {
    TestStore(initialState: state) {
        OnboardingRouterFeature(
            signIn: signIn.signIn,
            signOut: signOut.signOut,
            policyConsentStatus: policyConsent.policyConsentStatus,
            consent: policyConsent.consent,
            updateCuration: { try await userInfo.updateCuration($0) },
            withdraw: accountWithdrawal.withdraw,
            deletesCompletedAccountOnSignIn: deletesCompletedAccountOnSignIn,
        )
    }
}
