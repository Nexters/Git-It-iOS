import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

// MARK: - OnboardingPreviewSupport

enum OnboardingPreviewSupport {
    static let requiredDocuments = [
        PolicyDocument(
            identifier: "privacy-policy",
            displayName: "개인정보 처리방침",
            version: "1",
            approvedURL: URL(string: "https://example.com/privacy-policy")!,
            isRequired: true,
        ),
        PolicyDocument(
            identifier: "terms-of-service",
            displayName: "서비스 이용 약관",
            version: "1",
            approvedURL: URL(string: "https://example.com/terms-of-service")!,
            isRequired: true,
        ),
    ]
}

extension OnboardingGuideFeature {
    static func previewStore(_ state: State) -> StoreOf<OnboardingGuideFeature> {
        Store(initialState: state) {
            OnboardingGuideFeature(
                signIn: OnboardingPreviewSignIn(),
                policyConsent: OnboardingPreviewPolicyConsent(),
                deleteMemberAccount: OnboardingPreviewDeleteMemberAccount(),
            )
        }
    }
}

extension CurationFeature {
    static func previewStore(_ state: State) -> StoreOf<CurationFeature> {
        Store(initialState: state) {
            CurationFeature(
                signOut: OnboardingPreviewSignOut(),
                completeCuration: OnboardingPreviewCompleteCuration(),
            )
        }
    }
}

extension OnboardingRouterFeature {
    static func previewStore(_ state: State) -> StoreOf<OnboardingRouterFeature> {
        Store(initialState: state) {
            OnboardingRouterFeature(
                signIn: OnboardingPreviewSignIn(),
                signOut: OnboardingPreviewSignOut(),
                policyConsent: OnboardingPreviewPolicyConsent(),
                completeCuration: OnboardingPreviewCompleteCuration(),
                deleteMemberAccount: OnboardingPreviewDeleteMemberAccount(),
            )
        }
    }
}
