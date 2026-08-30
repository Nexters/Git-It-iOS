import Testing

@testable import DataMember

@Suite("Data 회원 오류")
struct DataMemberErrorTests {

    @Test
    func `공급자 중립 실패 의미를 7개로 구분한다`() {
        #expect(DataMemberError.allCases == [
            .invalidRequest,
            .unauthorized,
            .temporarilyUnavailable,
            .transport,
            .decoding,
            .unexpectedStatus,
            .memberUnavailable,
        ])
    }

    @Test(arguments: [
        (404, "MEMBER-001", DataMemberError.memberUnavailable),
        (404, "OTHER-CODE", DataMemberError.unexpectedStatus),
        (500, "SERVER-001", DataMemberError.temporarilyUnavailable),
        (503, "SERVER-002", DataMemberError.temporarilyUnavailable),
    ])
    func `대표 서버 오류 코드를 매핑한다`(httpStatus: Int, code: String, expected: DataMemberError) {
        let serverError = ServerAPIError(httpStatus: httpStatus, code: code, message: nil, fieldErrors: nil)

        #expect(DataMemberError(from: serverError) == expected)
    }

    @Test
    func `계약된 404와 일반 404를 서로 다른 의미로 구분한다`() {
        let contracted = ServerAPIError(httpStatus: 404, code: "MEMBER-001", message: nil, fieldErrors: nil)
        let generic = ServerAPIError(httpStatus: 404, code: "OTHER-CODE", message: nil, fieldErrors: nil)

        #expect(DataMemberError(from: contracted) != DataMemberError(from: generic))
    }

}
