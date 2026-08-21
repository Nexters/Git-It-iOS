import Foundation
import InfrastructureNetworkClient
import Testing

@testable import DataMember

// MARK: - HTTPMemberRemoteTests

@Suite("HTTPMemberRemote")
struct HTTPMemberRemoteTests {

    @Test
    func `프로필 조회는 GET members me 경로와 Bearer 헤더를 사용한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"""
                    {"success":true,"data":{"name":"홍길동","email":"a@b.com","position":"BACKEND","careerLevel":"JUNIOR","thisWeekSolvedCount":1,"thisMonthSolvedCount":2,"streakDays":3,"weeklyChart":[]},"code":null,"message":null,"errors":null}
                    """#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        let profile = try await remote.fetchProfile()

        #expect(profile.name == "홍길동")
        let request = try #require(await transport.recordedRequests.first)
        #expect(request.url.path == "/api/v1/members/me")
        #expect(request.method == .get)
        #expect(request.headers["Authorization"] == "Bearer test-access-token")
    }

    @Test
    func `회원 탈퇴는 DELETE members me 경로로 전송한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"{"success":true,"data":{},"code":null,"message":null,"errors":null}"#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        try await remote.withdrawMember()

        let request = try #require(await transport.recordedRequests.first)
        #expect(request.method == .delete)
        #expect(request.url.path == "/api/v1/members/me")
    }

    @Test
    func `서버 오류 코드를 Data 오류로 변환한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 404,
                envelope: #"{"success":false,"data":null,"code":"MEMBER-001","message":"not found","errors":null}"#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        await #expect(throws: DataMemberError.memberUnavailable) {
            try await remote.fetchProfile()
        }
    }

}

extension HTTPMemberRemoteTests {
    private func makeRemote(transport: StubHTTPTransport) -> HTTPMemberRemote {
        let client = HTTPClient(
            baseURL: URL(string: "https://api.git-it.example.com")!,
            bodyCoding: JSONBodyCoding(),
            transport: transport,
        )
        return HTTPMemberRemote(client: client, accessTokenProvider: { "test-access-token" })
    }

    private func jsonResponse(
        statusCode: Int,
        envelope: String,
    ) -> HTTPTransportResponse {
        HTTPTransportResponse(statusCode: statusCode, headers: [:], body: Data(envelope.utf8))
    }
}
