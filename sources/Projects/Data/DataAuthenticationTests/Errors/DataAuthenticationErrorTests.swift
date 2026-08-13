import Testing

@testable import DataAuthentication

@Suite("Data 인증 오류")
struct DataAuthenticationErrorTests {
    @Test
    func `공급자 중립 실패 의미를 구분한다`() {
        #expect(DataAuthenticationError.allCases == [
            .cancelled,
            .temporarilyUnavailable,
            .storageFailure,
            .sessionStartRejected,
            .refreshRejectedOrExpired,
            .revocationFailure,
        ])
    }
}
