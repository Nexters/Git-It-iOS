import Testing

@testable import DataMember

@Suite("MemberEndpoint 계약")
struct MemberEndpointTests {

    @Test
    func `모든 operation은 Bearer 인증 헤더를 포함한다`() {
        let endpoints: [MemberEndpoint] = [
            .fetchProfile,
            .registerDeviceInfo,
            .curateMember,
            .updatePosition,
            .updateCareerLevel,
            .withdrawMember,
        ]

        for endpoint in endpoints {
            let headers = endpoint.headers(accessToken: "token-123")
            #expect(headers["Authorization"] == "Bearer token-123")
            #expect(headers["Accept"] == "application/json")
            #expect(headers["Content-Type"] == "application/json")
        }
    }

    @Test
    func `프로필 조회는 GET으로 요청한다`() {
        #expect(MemberEndpoint.fetchProfile.method == .get)
        #expect(MemberEndpoint.fetchProfile.path == "/api/v1/members/me")
    }

    @Test
    func `기기 정보 등록은 POST로 요청한다`() {
        #expect(MemberEndpoint.registerDeviceInfo.method == .post)
        #expect(MemberEndpoint.registerDeviceInfo.path == "/api/v1/members/me/device")
    }

    @Test
    func `큐레이션은 POST로 요청한다`() {
        #expect(MemberEndpoint.curateMember.method == .post)
        #expect(MemberEndpoint.curateMember.path == "/api/v1/members/me/curation")
    }

    @Test
    func `분야 변경은 POST로 요청한다`() {
        #expect(MemberEndpoint.updatePosition.method == .post)
        #expect(MemberEndpoint.updatePosition.path == "/api/v1/members/me/position")
    }

    @Test
    func `수준 변경은 POST로 요청한다`() {
        #expect(MemberEndpoint.updateCareerLevel.method == .post)
        #expect(MemberEndpoint.updateCareerLevel.path == "/api/v1/members/me/career-level")
    }

    @Test
    func `회원 탈퇴는 DELETE로 요청한다`() {
        #expect(MemberEndpoint.withdrawMember.method == .delete)
        #expect(MemberEndpoint.withdrawMember.path == "/api/v1/members/me")
    }

}
