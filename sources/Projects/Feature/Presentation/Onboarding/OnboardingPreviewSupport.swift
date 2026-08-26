import ComposableArchitecture
import DomainAuthentication
import DomainMember
import Foundation

// MARK: - Preview 전용 Domain Test Double

/// 화면 파일 하단 `#Preview`가 결정적인 상태를 그리기 위한 최소 구현이다. production 조립에는
/// 관여하지 않으며 `OnboardingFeature.previewStore(state:)`를 통해서만 사용한다.
struct OnboardingPreviewRestoreSession: RestoreSessionUseCase {
    func callAsFunction() async -> RestoreSessionResult { .unauthenticated }
}

struct OnboardingPreviewSignIn: SignInUseCase {
    func callAsFunction(_ method: AuthenticationMethod) async -> SignInResult { .retryableFailure }
}

struct OnboardingPreviewSignOut: SignOutUseCase {
    func callAsFunction() async -> SignOutResult { .success }
}

struct OnboardingPreviewFetchMemberProfile: FetchMemberProfileUseCase {
    func callAsFunction() async throws -> MemberProfile {
        MemberProfile(
            name: "미리보기",
            email: "preview@example.com",
            position: nil,
            careerLevel: nil,
            statistics: LearningStatistics(totalAnsweredCount: 0, totalCorrectCount: 0, weeklyCounts: []),
        )
    }
}

struct OnboardingPreviewCompleteCuration: CompleteCurationUseCase {
    func callAsFunction(position: MemberPosition, careerLevel: CareerLevel) async throws { }
}

struct OnboardingPreviewPolicyConsent: PolicyConsentUseCase {
    func requiredDocuments() async throws -> [PolicyDocument] {
        OnboardingPreviewSupport.requiredDocuments
    }

    func storedConsentRecords() async throws -> [PolicyConsentRecord] { [] }
    func saveConsentRecords(_ records: [PolicyConsentRecord]) async throws { }

    func isConsentValid(
        storedRecords: [PolicyConsentRecord],
        for requiredDocuments: [PolicyDocument],
    ) -> Bool {
        PolicyConsentRecord.isConsentValid(storedRecords: storedRecords, for: requiredDocuments)
    }
}

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

extension OnboardingFeature {
    /// screen-local `#Preview`가 사용하는 deterministic Store다. production 조립(App)과는
    /// 무관하며 이 파일 밖에서 재사용하지 않는다.
    static func previewStore(_ state: State) -> StoreOf<OnboardingFeature> {
        Store(initialState: state) {
            OnboardingFeature(
                restoreSession: OnboardingPreviewRestoreSession(),
                signIn: OnboardingPreviewSignIn(),
                signOut: OnboardingPreviewSignOut(),
                fetchMemberProfile: OnboardingPreviewFetchMemberProfile(),
                completeCuration: OnboardingPreviewCompleteCuration(),
                policyConsent: OnboardingPreviewPolicyConsent(),
            )
        }
    }
}
