import Testing

@testable import DataMember

@Suite("서버 오류 값")
struct ServerAPIErrorTests {

    @Test
    func `HTTP status와 code, message, fieldErrors를 보존한다`() {
        let error = ServerAPIError(
            httpStatus: 404,
            code: "MEMBER-001",
            message: "not found",
            fieldErrors: [FieldErrorDTO(field: "memberId", message: "unknown")],
        )

        #expect(error.httpStatus == 404)
        #expect(error.code == "MEMBER-001")
        #expect(error.message == "not found")
        #expect(error.fieldErrors == [FieldErrorDTO(field: "memberId", message: "unknown")])
    }

}
