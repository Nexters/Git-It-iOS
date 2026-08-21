import Foundation
import InfrastructureNetworkClient
import Testing

@testable import DataAuthentication

// MARK: - HTTPAuthenticationRemoteTests

@Suite("HTTPAuthenticationRemote")
struct HTTPAuthenticationRemoteTests {

    @Test
    func `Apple 로그인 요청을 idToken 본문으로 구성하고 응답을 반환한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"""
                    {"success":true,"data":{"accessToken":"access","refreshToken":"refresh","needsCuration":false},"code":null,"message":null,"errors":null}
                    """#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        let response = try await remote.appleLogin(idToken: "apple-id-token")

        #expect(response.accessToken == "access")
        #expect(response.refreshToken == "refresh")
        let request = await transport.recordedRequests.first
        #expect(request?.url.path == "/api/v1/auth/login/apple")
        let body = try #require(request?.body)
        let decodedBody = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
        #expect(decodedBody["idToken"] == "apple-id-token")
    }

    @Test
    func `Access Token 확인 요청에 Bearer 헤더를 포함한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"{"success":true,"data":{},"code":null,"message":null,"errors":null}"#,
            ))
        ])
        let remote = makeRemote(transport: transport, accessToken: "stored-token")

        try await remote.verifyAccessToken()

        let request = await transport.recordedRequests.first
        #expect(request?.headers["Authorization"] == "Bearer stored-token")
        #expect(request?.url.path == "/api/v1/auth/token")
    }

    @Test
    func `서버 오류 상태를 Data 오류로 변환한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 401,
                envelope: #"{"success":false,"data":null,"code":null,"message":"unauthorized","errors":null}"#,
            ))
        ])
        let remote = makeRemote(transport: transport, accessToken: "expired-token")

        await #expect(throws: DataAuthenticationError.unauthorized) {
            try await remote.verifyAccessToken()
        }
    }

    @Test
    func `응답 디코딩 실패를 decoding 오류로 변환한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(HTTPTransportResponse(statusCode: 200, headers: [:], body: Data("not-json".utf8)))
        ])
        let remote = makeRemote(transport: transport)

        await #expect(throws: DataAuthenticationError.decoding) {
            try await remote.appleLogin(idToken: "apple-id-token")
        }
    }

    @Test
    func `취소를 CancellationError로 그대로 전달한다`() async throws {
        let transport = StubHTTPTransport(results: [.failure(.cancelled)])
        let remote = makeRemote(transport: transport)

        await #expect(throws: CancellationError.self) {
            try await remote.appleLogin(idToken: "apple-id-token")
        }
    }

}

extension HTTPAuthenticationRemoteTests {
    private func makeRemote(
        transport: StubHTTPTransport,
        accessToken: String? = nil,
    ) -> HTTPAuthenticationRemote {
        let client = HTTPClient(
            baseURL: URL(string: "https://api.git-it.example.com")!,
            bodyCoding: JSONBodyCoding(),
            transport: transport,
        )
        return HTTPAuthenticationRemote(client: client, accessTokenProvider: { accessToken })
    }

    private func jsonResponse(
        statusCode: Int,
        envelope: String,
    ) -> HTTPTransportResponse {
        HTTPTransportResponse(statusCode: statusCode, headers: [:], body: Data(envelope.utf8))
    }
}
