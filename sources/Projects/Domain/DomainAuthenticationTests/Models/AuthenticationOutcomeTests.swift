import Testing

@testable import DomainAuthentication

@Suite("인증 결과")
struct AuthenticationOutcomeTests {
    @Test
    func `안전한 사용자 또는 비인증 및 복구 가능 실패만 전달한다`() {
        let user = AuthenticatedUser(
            id: "user-1",
            availability: .available,
            displayName: nil,
        )
        let outcomes: [AuthenticationOutcome] = [
            .authenticated(user),
            .unauthenticated,
            .recoverableFailure,
        ]

        #expect(outcomes[0] == .authenticated(user))
        #expect(outcomes[1] == .unauthenticated)
        #expect(outcomes[2] == .recoverableFailure)

        for outcome in outcomes {
            let fieldNames = Mirror(reflecting: outcome).children.compactMap(\.label)
            #expect(!fieldNames.contains("token"))
            #expect(!fieldNames.contains("error"))
        }
    }
}
