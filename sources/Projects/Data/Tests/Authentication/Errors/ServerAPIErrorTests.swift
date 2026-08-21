import Testing

@testable import DataAuthentication

@Suite("서버 오류 값")
struct ServerAPIErrorTests {

    @Test
    func `HTTP status와 code, message, fieldErrors를 보존한다`() {
        let error = ServerAPIError(
            httpStatus: 404,
            code: "PROJECT-001",
            message: "not found",
            fieldErrors: [FieldErrorDTO(field: "projectId", message: "unknown")],
        )

        #expect(error.httpStatus == 404)
        #expect(error.code == "PROJECT-001")
        #expect(error.message == "not found")
        #expect(error.fieldErrors == [FieldErrorDTO(field: "projectId", message: "unknown")])
    }

    @Test
    func `code와 message, fieldErrors가 없어도 구성할 수 있다`() {
        let error = ServerAPIError(httpStatus: 500, code: nil, message: nil, fieldErrors: nil)

        #expect(error.httpStatus == 500)
        #expect(error.code == nil)
        #expect(error.message == nil)
        #expect(error.fieldErrors == nil)
    }

}
