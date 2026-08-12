import Testing

@testable import DomainAuthentication

// MARK: - SensitiveValueExposureTests

@Suite("Domain 민감 값 비노출")
struct SensitiveValueExposureTests {
    @Test
    func `모델과 오류의 필드 및 문자열 표현에 외부 인증 비밀이 없다`() {
        let user = AuthenticatedUser(
            id: "user-1",
            availability: .available,
            displayName: nil,
        )
        let values: [Any] = [
            AuthenticationMethod.apple,
            AuthenticationGrant(id: .init(rawValue: "grant-1"), method: .apple),
            user,
            AuthenticationOutcome.authenticated(user),
            AuthenticationOutcome.unauthenticated,
            AuthenticationOutcome.recoverableFailure,
            AuthenticationAuthorizationStatus.authorized,
            AuthenticationError.cancelled,
            AuthenticationError.temporarilyUnavailable,
            SessionError.temporarilyUnavailable,
            SessionError.refreshRejectedOrExpired,
            SessionError.accountUnavailable,
        ]
        let forbiddenTerms = [
            "authenticationservices",
            "asauthorization",
            "identitytoken",
            "authorizationcode",
            "credential",
            "token",
            "nonce",
            "state",
        ]

        for value in values {
            let fieldNames = recursiveFieldNames(of: value).map { $0.lowercased() }
            let reflectedValue = String(reflecting: value).lowercased()

            for term in forbiddenTerms {
                #expect(fieldNames.allSatisfy { !$0.contains(term) })
                #expect(!reflectedValue.contains(term))
            }
        }
    }
}

extension SensitiveValueExposureTests {
    private func recursiveFieldNames(of value: Any) -> [String] {
        let mirror = Mirror(reflecting: value)
        return mirror.children.flatMap { child in
            let currentLabel = child.label.map { [$0] } ?? []
            return currentLabel + recursiveFieldNames(of: child.value)
        }
    }
}
