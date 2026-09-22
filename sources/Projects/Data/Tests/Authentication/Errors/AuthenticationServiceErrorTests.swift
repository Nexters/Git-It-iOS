import Testing

@testable import DataAuthentication

@Suite("Data 인증 오류")
struct AuthenticationServiceErrorTests {

    @Test
    func `공급자 중립 실패 의미를 5개로 구분한다`() {
        #expect(AuthenticationServiceError.allCases == [
            .invalidRequest,
            .unauthorized,
            .temporarilyUnavailable,
            .transport,
            .unexpectedStatus,
        ])
    }

    @Test(arguments: [
        (400, "COMMON-001", AuthenticationServiceError.invalidRequest),
        (401, "COMMON-002", AuthenticationServiceError.unauthorized),
        (500, "COMMON-005", AuthenticationServiceError.temporarilyUnavailable),
        (418, "TEAPOT-001", AuthenticationServiceError.unexpectedStatus),
    ])
    func `대표 서버 오류 코드를 매핑한다`(httpStatus: Int, code: String, expected: AuthenticationServiceError) {
        let serverError = ServerAPIError(
            httpStatus: httpStatus,
            code: code,
            message: nil,
            fieldErrors: nil,
        )

        #expect(AuthenticationServiceError(from: serverError) == expected)
    }

}
