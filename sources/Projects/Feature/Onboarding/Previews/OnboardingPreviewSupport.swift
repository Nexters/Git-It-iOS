import DomainAuthentication
import DomainMember
import Foundation

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
