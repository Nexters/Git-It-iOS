import Testing

@testable import DomainAuthentication

@Suite("세션 오류")
struct SessionErrorTests {
    @Test
    func `일시 실패와 명시적 무효화 및 계정 이용 불가를 구분한다`() {
        #expect(
            SessionError.allCases == [
                .temporarilyUnavailable,
                .refreshRejectedOrExpired,
                .accountUnavailable,
            ]
        )
    }
}
