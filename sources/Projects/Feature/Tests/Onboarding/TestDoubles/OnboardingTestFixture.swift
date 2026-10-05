import DomainUseCaseInterface
import Foundation

enum OnboardingTestFixture {
    static let privacyPolicy = PolicyDocument(
        id: "privacy-policy",
        displayName: "개인정보 처리방침",
        version: "1",
        approvedURL: URL(string: "https://example.com/privacy-policy")!,
        isRequired: true,
    )

    static let termsOfService = PolicyDocument(
        id: "terms-of-service",
        displayName: "서비스 이용 약관",
        version: "1",
        approvedURL: URL(string: "https://example.com/terms-of-service")!,
        isRequired: true,
    )

    static let requiredDocuments = [privacyPolicy, termsOfService]

    static let satisfiedConsentStatus = PolicyConsentStatus(
        documents: requiredDocuments,
        consents: requiredDocuments.map {
            PolicyConsent(
                documentID: $0.id,
                version: $0.version,
                consentedAt: Date(),
            )
        },
        isSatisfied: true,
    )

    static let pendingConsentStatus = PolicyConsentStatus(
        documents: requiredDocuments,
        consents: [],
        isSatisfied: false,
    )

    static func signedInAccount(needsCuration: Bool) -> SignedInAccount {
        SignedInAccount(
            id: "member-1",
            displayName: "테스터",
            needsCuration: needsCuration,
        )
    }

    static func profile(
        position: MemberPosition?,
        careerLevel: CareerLevel?,
    ) -> UserProfile {
        let curation: Curation? =
            if let position, let careerLevel {
                Curation(
                    position: position,
                    careerLevel: careerLevel,
                )
            } else {
                nil
            }
        return UserProfile(
            detail: UserDetail(
                name: "테스터",
                email: "tester@example.com",
                statistics: LearningStatistics(
                    thisWeekSolvedCount: 0,
                    thisMonthSolvedCount: 0,
                    streakDays: 0,
                    weeklyCounts: [],
                ),
            ),
            curation: curation,
        )
    }
}
