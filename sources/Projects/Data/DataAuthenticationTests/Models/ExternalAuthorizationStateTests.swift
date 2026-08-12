import Testing

@testable import DataAuthentication

@Suite("외부 authorization 상태")
struct ExternalAuthorizationStateTests {
    @Test
    func `공급자 중립 상태 세 가지만 제공한다`() {
        #expect(ExternalAuthorizationState.allCases == [
            .active,
            .inactive,
            .temporarilyUnavailable,
        ])
        #expect(!ExternalAuthorizationState.allCases.map(String.init(describing:)).contains("revoked"))
    }
}
