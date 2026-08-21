import Testing

@testable import DataMember

@Suite("MemberRemote 계약 — 큐레이션·분야·수준 변경")
struct MemberPreferenceContractTests {

    @Test
    func `큐레이션 정보를 등록한다`() async throws {
        let remote = MemberRemoteProbe()
        let request = CurationRequestDTO(
            position: PositionDTO(rawValue: "BACKEND"),
            careerLevel: CareerLevelDTO(rawValue: "JUNIOR"),
        )

        try await remote.curateMember(request)

        #expect(await remote.recordedCalls() == [.curateMember])
    }

    @Test
    func `분야를 변경한다`() async throws {
        let remote = MemberRemoteProbe()
        let request = PositionRequestDTO(position: PositionDTO(rawValue: "FRONTEND"))

        try await remote.updatePosition(request)

        #expect(await remote.recordedCalls() == [.updatePosition])
    }

    @Test
    func `수준을 변경한다`() async throws {
        let remote = MemberRemoteProbe()
        let request = CareerLevelRequestDTO(careerLevel: CareerLevelDTO(rawValue: "SENIOR"))

        try await remote.updateCareerLevel(request)

        #expect(await remote.recordedCalls() == [.updateCareerLevel])
    }

}
