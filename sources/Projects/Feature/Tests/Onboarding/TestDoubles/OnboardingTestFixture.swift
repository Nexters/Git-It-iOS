import DomainAuthentication
import DomainMember
import Foundation

enum OnboardingTestFixture {
    static let privacyPolicy = PolicyDocument(
        identifier: "privacy-policy",
        displayName: "개인정보 처리방침",
        version: "1",
        approvedURL: URL(string: "https://example.com/privacy-policy")!,
        isRequired: true,
    )

    static let termsOfService = PolicyDocument(
        identifier: "terms-of-service",
        displayName: "서비스 이용 약관",
        version: "1",
        approvedURL: URL(string: "https://example.com/terms-of-service")!,
        isRequired: true,
    )

    static let requiredDocuments = [privacyPolicy, termsOfService]

    static let validConsentRecords = [
        PolicyConsentRecord(documentIdentifier: privacyPolicy.identifier, version: privacyPolicy.version, acceptedAt: Date()),
        PolicyConsentRecord(documentIdentifier: termsOfService.identifier, version: termsOfService.version, acceptedAt: Date()),
    ]

    static let authenticatedUser = AuthenticatedUser(id: "member-1", availability: .available, displayName: "테스터")

    static func profile(
        position: MemberPosition?,
        careerLevel: CareerLevel?,
    ) -> MemberProfile {
        MemberProfile(
            name: "테스터",
            email: "tester@example.com",
            position: position,
            careerLevel: careerLevel,
            statistics: LearningStatistics(totalAnsweredCount: 0, totalCorrectCount: 0, weeklyCounts: []),
        )
    }
}
