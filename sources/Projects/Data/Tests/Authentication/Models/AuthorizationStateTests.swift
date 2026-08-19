import Testing

@testable import DataAuthentication

@Suite("AuthorizationState")
struct AuthorizationStateTests {
    @Test
    func `공급자 중립 상태 세 가지만 제공한다`() {
        #expect(AuthorizationState.allCases == [
            .active,
            .inactive,
            .temporarilyUnavailable,
        ])
        #expect(!AuthorizationState.allCases.map(String.init(describing:)).contains("revoked"))
    }
}
