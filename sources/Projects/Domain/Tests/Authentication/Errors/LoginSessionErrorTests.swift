import Testing

@testable import DomainAuthentication

@Suite("로그인 세션 오류")
struct LoginSessionErrorTests {
    @Test
    func `일시 실패와 명시적 무효화 및 계정 이용 불가를 구분한다`() {
        #expect(
            LoginSessionError.allCases == [
                .temporarilyUnavailable,
                .refreshRejectedOrExpired,
                .accountUnavailable,
                .unauthorized,
            ]
        )
    }
}
