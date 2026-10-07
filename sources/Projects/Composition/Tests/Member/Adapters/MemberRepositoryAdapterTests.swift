import Foundation
import Testing

@testable import CompositionMember
@testable import DataMember
@testable import DomainMember
@testable import InfrastructureNetworkClient

// MARK: - MemberRepositoryAdapterTests

@Suite("MemberRepositoryAdapter")
struct MemberRepositoryAdapterTests {

    // MARK: Internal

    @Test
    func `프로필 응답 DTO를 Domain MemberProfile로 변환한다`() async throws {
        let adapter = makeAdapter(transport: RecordingHTTPTransport(results: [
            profileResponse(
                position: #""BACKEND""#,
                careerLevel: #""JUNIOR""#,
                weeklyChart: #"[{"dayLabel":"월","count":3}]"#,
                thisWeekSolvedCount: 3,
                thisMonthSolvedCount: 12,
                streakDays: 5,
            )
        ]))

        let profile = try await adapter.fetchProfile()

        #expect(profile.name == "홍길동")
        #expect(profile.position == .backend)
        #expect(profile.careerLevel == .junior)
        #expect(profile.statistics.thisWeekSolvedCount == 3)
        #expect(profile.statistics.thisMonthSolvedCount == 12)
        #expect(profile.statistics.streakDays == 5)
        #expect(profile.statistics.weeklyCounts.count == 1)
        #expect(profile.statistics.weeklyCounts.first?.dayLabel == "월")
        #expect(profile.statistics.weeklyCounts.first?.count == 3)
    }

    @Test
    func `position·career raw wire value를 대문자로 매핑해 전송한다`() async throws {
        let transport = RecordingHTTPTransport(results: [emptyResponse()])
        let adapter = makeAdapter(transport: transport)

        try await adapter.updatePosition(.frontend)

        let request = try #require(await transport.recordedRequests.first)
        #expect(request.url.path == "/api/v1/members/me/position")
        let rawBody = try #require(request.body)
        let body = try #require(JSONSerialization.jsonObject(with: rawBody) as? [String: String])
        #expect(body["position"] == "FRONTEND")
    }

    @Test
    func `Data 오류를 Domain 오류로 변환한다`() async throws {
        let adapter = makeAdapter(transport: RecordingHTTPTransport(results: [
            errorResponse(statusCode: 404, code: #""MEMBER-001""#)
        ]))

        await #expect(throws: MemberError.memberUnavailable) {
            try await adapter.fetchProfile()
        }
    }

    @Test
    func `position과 careerLevel이 모두 null이면 nil로 보존한다`() async throws {
        let adapter = makeAdapter(transport: RecordingHTTPTransport(results: [
            profileResponse(position: "null", careerLevel: "null")
        ]))

        let profile = try await adapter.fetchProfile()

        #expect(profile.position == nil)
        #expect(profile.careerLevel == nil)
    }

    @Test
    func `한 필드만 null이면 다른 필드는 그대로 매핑된다`() async throws {
        let adapter = makeAdapter(transport: RecordingHTTPTransport(results: [
            profileResponse(position: #""IOS""#, careerLevel: "null")
        ]))

        let profile = try await adapter.fetchProfile()

        #expect(profile.position == .ios)
        #expect(profile.careerLevel == nil)
    }

    @Test
    func `지원하지 않는 non-null raw value는 nil로 치환하지 않고 decoding 오류로 처리한다`() async throws {
        let adapter = makeAdapter(transport: RecordingHTTPTransport(results: [
            profileResponse(position: #""WEB""#, careerLevel: #""JUNIOR""#)
        ]))

        await #expect(throws: MemberError.temporarilyUnavailable) {
            try await adapter.fetchProfile()
        }
    }

    @Test
    func `전송 실패를 재시도 가능한 Domain 오류로 변환한다`() async throws {
        let adapter = makeAdapter(transport: RecordingHTTPTransport(results: []))

        await #expect(throws: MemberError.temporarilyUnavailable) {
            try await adapter.fetchProfile()
        }
    }

    @Test
    func `서버 5xx 응답을 재시도 가능한 Domain 오류로 변환한다`() async throws {
        let adapter = makeAdapter(transport: RecordingHTTPTransport(results: [
            errorResponse(statusCode: 503, code: "null")
        ]))

        await #expect(throws: MemberError.temporarilyUnavailable) {
            try await adapter.fetchProfile()
        }
    }

    // MARK: Private

    private func makeAdapter(transport: RecordingHTTPTransport) -> MemberRepositoryAdapter {
        MemberRepositoryAdapter(remote: HTTPMemberRemote(
            client: HTTPClient(
                baseURL: URL(string: "https://api.git-it.example.com")!,
                bodyCoding: StandardJSONBodyCoding(),
                transport: transport,
            ),
            accessTokenProvider: { "test-access-token" },
        ))
    }

    private func profileResponse(
        position: String,
        careerLevel: String,
        weeklyChart: String = "[]",
        thisWeekSolvedCount: Int = 0,
        thisMonthSolvedCount: Int = 0,
        streakDays: Int = 0,
    ) -> HTTPTransportResponse {
        let envelope = """
            {"success":true,"data":{"name":"홍길동","email":"a@b.com","position":\(position),\
            "careerLevel":\(careerLevel),"thisWeekSolvedCount":\(thisWeekSolvedCount),\
            "thisMonthSolvedCount":\(thisMonthSolvedCount),"streakDays":\(streakDays),\
            "weeklyChart":\(weeklyChart)},"code":null,"message":null,"errors":null}
            """
        return HTTPTransportResponse(statusCode: 200, headers: [:], body: Data(envelope.utf8))
    }

    private func emptyResponse() -> HTTPTransportResponse {
        HTTPTransportResponse(
            statusCode: 200,
            headers: [:],
            body: Data(#"{"success":true,"data":{},"code":null,"message":null,"errors":null}"#.utf8),
        )
    }

    private func errorResponse(
        statusCode: Int,
        code: String,
    ) -> HTTPTransportResponse {
        HTTPTransportResponse(
            statusCode: statusCode,
            headers: [:],
            body: Data("""
                {"success":false,"data":null,"code":\(code),"message":"error","errors":null}
                """.utf8),
        )
    }

}
