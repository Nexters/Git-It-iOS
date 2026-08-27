import Testing
@testable import DataMember

struct MemberRemoteContractTests {

    @Test
    func `프로필을 조회한다`() async throws {
        let remote = MemberRemoteProbe()

        let profile = try await remote.fetchProfile()

        #expect(profile.name == "테스터")
        #expect(await remote.recordedCalls() == [.fetchProfile])
    }

    @Test
    func `회원을 탈퇴한다`() async throws {
        let remote = MemberRemoteProbe()

        try await remote.withdrawMember()

        #expect(await remote.recordedCalls() == [.withdrawMember])
    }

}
