import Testing

@testable import DataAuthentication

@Suite("AuthenticationEndpoint 계약")
struct AuthenticationEndpointTests {

    @Test
    func `Apple 로그인은 인증 헤더 없이 POST로 요청한다`() {
        let endpoint = AuthenticationEndpoint.appleLogin

        #expect(endpoint.method == .post)
        #expect(endpoint.path == "/api/v1/auth/login/apple")
        #expect(endpoint.headers(accessToken: nil)["Authorization"] == nil)
        #expect(endpoint.headers(accessToken: nil)["Accept"] == "application/json")
        #expect(endpoint.headers(accessToken: nil)["Content-Type"] == "application/json")
    }

    @Test
    func `Access Token 확인은 GET으로 요청한다`() {
        let endpoint = AuthenticationEndpoint.verifyAccessToken

        #expect(endpoint.method == .get)
        #expect(endpoint.path == "/api/v1/auth/token")
        #expect(endpoint.headers(accessToken: "token-123")["Authorization"] == "Bearer token-123")
        #expect(endpoint.headers(accessToken: "token-123")["Accept"] == "application/json")
        #expect(endpoint.headers(accessToken: "token-123")["Content-Type"] == "application/json")
    }

}
