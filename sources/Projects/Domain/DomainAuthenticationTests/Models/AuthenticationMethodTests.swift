import Testing

@testable import DomainAuthentication

@Suite("인증 방식")
struct AuthenticationMethodTests {
    @Test
    func `Apple 인증 방식을 외부 프레임워크 타입 없이 표현한다`() {
        let method = AuthenticationMethod.apple

        #expect(method == .apple)
        #expect(AuthenticationMethod.allCases == [.apple])
        #expect(Mirror(reflecting: method).children.isEmpty)

        let reflectedValue = String(reflecting: method)
        #expect(!reflectedValue.contains("AuthenticationServices"))
        #expect(!reflectedValue.contains("ASAuthorization"))
    }
}
