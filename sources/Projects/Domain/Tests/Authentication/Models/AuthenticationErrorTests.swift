import Testing

@testable import DomainAuthentication

@Suite("인증 오류")
struct AuthenticationErrorTests {
    @Test
    func `사용자 취소와 복구 가능한 외부 인증 실패를 구분한다`() {
        #expect(AuthenticationError.allCases == [.cancelled, .invalidCallback, .temporarilyUnavailable])
        #expect(AuthenticationError.cancelled != .temporarilyUnavailable)

        let reflectedValues = AuthenticationError.allCases.map { String(reflecting: $0) }
        #expect(reflectedValues.allSatisfy { !$0.contains("ASAuthorization") })
        #expect(reflectedValues.allSatisfy { !$0.contains("credential") })
    }
}
