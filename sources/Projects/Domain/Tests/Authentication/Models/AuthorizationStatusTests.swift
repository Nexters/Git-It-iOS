import Testing

@testable import DomainAuthentication

@Suite("인증 권한 상태")
struct AuthorizationStatusTests {
    @Test
    func `공급자 중립 상태 세 가지만 공개한다`() {
        #expect(
            AuthorizationStatus.allCases == [
                .authorized,
                .reauthenticationRequired,
                .temporarilyUnavailable,
            ]
        )
    }
}
