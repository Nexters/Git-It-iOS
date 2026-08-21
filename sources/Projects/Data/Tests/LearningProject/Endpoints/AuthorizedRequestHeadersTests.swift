import Testing

@testable import DataLearningProject

@Suite("학습 프로젝트 요청 헤더 조립")
struct AuthorizedRequestHeadersTests {

    @Test
    func `Bearer 인증과 JSON 헤더를 조립한다`() {
        let headers = AuthorizedRequestHeaders(accessToken: "token-123")

        #expect(headers.fieldValues["Authorization"] == "Bearer token-123")
        #expect(headers.fieldValues["Accept"] == "application/json")
        #expect(headers.fieldValues["Content-Type"] == "application/json")
    }

    @Test
    func `access token이 다르면 서로 다른 헤더를 만든다`() {
        #expect(AuthorizedRequestHeaders(accessToken: "a") != AuthorizedRequestHeaders(accessToken: "b"))
    }

}
