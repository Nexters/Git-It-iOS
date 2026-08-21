import Testing

@testable import DataAuthentication

@Suite("Data 인증 오류")
struct DataAuthenticationErrorTests {

    @Test
    func `공급자 중립 실패 의미를 6개로 구분한다`() {
        #expect(DataAuthenticationError.allCases == [
            .invalidRequest,
            .unauthorized,
            .temporarilyUnavailable,
            .transport,
            .decoding,
            .unexpectedStatus,
        ])
    }

    @Test(arguments: [
        (400, "COMMON-001", DataAuthenticationError.invalidRequest),
        (401, "COMMON-002", DataAuthenticationError.unauthorized),
        (500, "COMMON-005", DataAuthenticationError.temporarilyUnavailable),
        (418, "TEAPOT-001", DataAuthenticationError.unexpectedStatus),
    ])
    func `대표 서버 오류 코드를 매핑한다`(httpStatus: Int, code: String, expected: DataAuthenticationError) {
        let serverError = ServerAPIError(httpStatus: httpStatus, code: code, message: nil, fieldErrors: nil)

        #expect(DataAuthenticationError(from: serverError) == expected)
    }

}
