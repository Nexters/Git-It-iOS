import Foundation
import Testing

@testable import InfrastructureAuthentication

@Suite("Infrastructure 민감 값 비노출")
struct SensitiveValueExposureTests {
    @Test
    func `Apple credential nonce state와 Keychain 값이 설명 문자열에 포함되지 않는다`() {
        let credential = AppleCredential(
            userID: "user",
            identityToken: Data("identity-marker".utf8),
            authorizationCode: Data("code-marker".utf8),
            email: nil,
            fullName: nil,
        )
        let attempt = AppleAuthorizationAttempt(
            id: "attempt-marker",
            nonce: "nonce-marker",
            state: "state-marker",
            expiresAt: .now,
        )
        let values: [Any] = [credential, attempt, KeychainStoreError.unavailable]

        for value in values {
            let output = "\(String(describing: value)) \(String(reflecting: value))"
            #expect(!output.contains("identity-marker"))
            #expect(!output.contains("code-marker"))
            #expect(!output.contains("nonce-marker"))
            #expect(!output.contains("state-marker"))
        }
    }
}
