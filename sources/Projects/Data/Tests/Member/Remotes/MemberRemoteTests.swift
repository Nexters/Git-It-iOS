import Foundation
import InfrastructureNetworkClient
import Testing

@testable import DataMember

// MARK: - MemberRemoteTests

@Suite("MemberRemote")
struct MemberRemoteTests {

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
    func `기기 정보 등록은 deviceType을 ios 고정값으로 본문에 담는다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"{"success":true,"data":{},"code":null,"message":null,"errors":null}"#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        try await remote.registerDeviceInfo(DeviceInfoRequestDTO(
            deviceID: "device-1",
            deviceType: "ios",
            appVersion: "1.0.0",
            osVersion: "18.0",
            deviceToken: "token-abc",
        ))

        let request = try #require(await transport.recordedRequests.first)
        #expect(request.method == .post)
        #expect(request.url.path == "/api/v1/members/me/device")
        let rawBody = try #require(request.body)
        let body = try #require(JSONSerialization.jsonObject(with: rawBody) as? [String: String])
        #expect(body["deviceType"] == "ios")
        #expect(body["deviceId"] == "device-1")
        #expect(body["deviceToken"] == "token-abc")
    }

    @Test
    func `큐레이션 등록은 분야와 수준을 본문에 담아 curation 경로로 전송한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"{"success":true,"data":{},"code":null,"message":null,"errors":null}"#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        try await remote.curateMember(CurationRequestDTO(
            position: PositionDTO(rawValue: "BACKEND"),
            careerLevel: CareerLevelDTO(rawValue: "JUNIOR"),
        ))

        let request = try #require(await transport.recordedRequests.first)
        #expect(request.method == .post)
        #expect(request.url.path == "/api/v1/members/me/curation")
        let rawBody = try #require(request.body)
        let body = try #require(JSONSerialization.jsonObject(with: rawBody) as? [String: String])
        #expect(body["position"] == "BACKEND")
        #expect(body["careerLevel"] == "JUNIOR")
    }

    @Test
    func `분야 변경은 position 경로로 전송한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"{"success":true,"data":{},"code":null,"message":null,"errors":null}"#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        try await remote.updatePosition(PositionRequestDTO(position: PositionDTO(rawValue: "FRONTEND")))

        let request = try #require(await transport.recordedRequests.first)
        #expect(request.url.path == "/api/v1/members/me/position")
        let rawBody = try #require(request.body)
        let body = try #require(JSONSerialization.jsonObject(with: rawBody) as? [String: String])
        #expect(body["position"] == "FRONTEND")
    }

    @Test
    func `수준 변경은 career-level 경로로 전송한다`() async throws {
        let transport = StubHTTPTransport(results: [
            .response(jsonResponse(
                statusCode: 200,
                envelope: #"{"success":true,"data":{},"code":null,"message":null,"errors":null}"#,
            ))
        ])
        let remote = makeRemote(transport: transport)

        try await remote.updateCareerLevel(CareerLevelRequestDTO(careerLevel: CareerLevelDTO(rawValue: "SENIOR")))

        let request = try #require(await transport.recordedRequests.first)
        #expect(request.url.path == "/api/v1/members/me/career-level")
        let rawBody = try #require(request.body)
        let body = try #require(JSONSerialization.jsonObject(with: rawBody) as? [String: String])
        #expect(body["careerLevel"] == "SENIOR")
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

        await #expect(throws: MemberServiceError.memberUnavailable) {
            try await remote.fetchProfile()
        }
    }

}

extension MemberRemoteTests {
    private func makeRemote(transport: StubHTTPTransport) -> MemberRemote {
        let client = HTTPClient(
            baseURL: URL(string: "https://api.git-it.example.com")!,
            bodyCoding: JSONBodyCoding(),
            transport: transport,
        )
        return MemberRemote(
            client: client,
            credential: { .available("test-access-token") },
            credentialRejected: { },
        )
    }

    private func jsonResponse(
        statusCode: Int,
        envelope: String,
    ) -> HTTPTransportResponse {
        HTTPTransportResponse(statusCode: statusCode, headers: [:], body: Data(envelope.utf8))
    }
}
