import Testing

@testable import DataMember

@Suite("Data 회원 오류")
struct MemberServiceErrorTests {

    @Test
    func `공급자 중립 실패 의미를 6개로 구분한다`() {
        #expect(MemberServiceError.allCases == [
            .invalidRequest,
            .unauthorized,
            .temporarilyUnavailable,
            .transport,
            .unexpectedStatus,
            .memberUnavailable,
        ])
    }

    @Test(arguments: [
        (404, "MEMBER-001", MemberServiceError.memberUnavailable),
        (404, "OTHER-CODE", MemberServiceError.unexpectedStatus),
        (500, "SERVER-001", MemberServiceError.temporarilyUnavailable),
        (503, "SERVER-002", MemberServiceError.temporarilyUnavailable),
    ])
    func `대표 서버 오류 코드를 매핑한다`(httpStatus: Int, code: String, expected: MemberServiceError) {
        let serverError = ServerAPIError(httpStatus: httpStatus, code: code, message: nil, fieldErrors: nil)

        #expect(MemberServiceError(from: serverError) == expected)
    }

    @Test
    func `계약된 404와 일반 404를 서로 다른 의미로 구분한다`() {
        let contracted = ServerAPIError(httpStatus: 404, code: "MEMBER-001", message: nil, fieldErrors: nil)
        let generic = ServerAPIError(httpStatus: 404, code: "OTHER-CODE", message: nil, fieldErrors: nil)

        #expect(MemberServiceError(from: contracted) != MemberServiceError(from: generic))
    }

}
