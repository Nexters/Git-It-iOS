import Testing

@testable import CompositionAdapter
@testable import DataMember
@testable import DomainMember

// MARK: - MemberRepositoryAdapterTests

@Suite("MemberRepositoryAdapter")
struct MemberRepositoryAdapterTests {

    @Test
    func `프로필 응답 DTO를 Domain MemberProfile로 변환한다`() async throws {
        let remote = StubMemberRemote(profileResult: .success(MemberProfileResponseDTO(
            name: "홍길동",
            email: "a@b.com",
            position: "BACKEND",
            careerLevel: "JUNIOR",
            thisWeekSolvedCount: 3,
            thisMonthSolvedCount: 12,
            streakDays: 5,
            weeklyChart: [WeeklyChartItemDTO(dayLabel: "월", count: 3)],
        )))
        let adapter = MemberRepositoryAdapter(remote: remote)

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
        let remote = StubMemberRemote()
        let adapter = MemberRepositoryAdapter(remote: remote)

        try await adapter.updatePosition(.frontend)

        let request = await remote.recordedPositionRequest
        #expect(request?.position.rawValue == "FRONTEND")
    }

    @Test
    func `Data 오류를 Domain 오류로 변환한다`() async throws {
        let remote = StubMemberRemote(profileResult: .failure(.memberUnavailable))
        let adapter = MemberRepositoryAdapter(remote: remote)

        await #expect(throws: MemberError.memberUnavailable) {
            try await adapter.fetchProfile()
        }
    }

    @Test
    func `position과 careerLevel이 모두 null이면 nil로 보존한다`() async throws {
        let remote = StubMemberRemote(profileResult: .success(MemberProfileResponseDTO(
            name: "홍길동",
            email: "a@b.com",
            position: nil,
            careerLevel: nil,
            thisWeekSolvedCount: 0,
            thisMonthSolvedCount: 0,
            streakDays: 0,
            weeklyChart: [],
        )))
        let adapter = MemberRepositoryAdapter(remote: remote)

        let profile = try await adapter.fetchProfile()

        #expect(profile.position == nil)
        #expect(profile.careerLevel == nil)
    }

    @Test
    func `한 필드만 null이면 다른 필드는 그대로 매핑된다`() async throws {
        let remote = StubMemberRemote(profileResult: .success(MemberProfileResponseDTO(
            name: "홍길동",
            email: "a@b.com",
            position: "IOS",
            careerLevel: nil,
            thisWeekSolvedCount: 0,
            thisMonthSolvedCount: 0,
            streakDays: 0,
            weeklyChart: [],
        )))
        let adapter = MemberRepositoryAdapter(remote: remote)

        let profile = try await adapter.fetchProfile()

        #expect(profile.position == .ios)
        #expect(profile.careerLevel == nil)
    }

    @Test
    func `지원하지 않는 non-null raw value는 nil로 치환하지 않고 decoding 오류로 처리한다`() async throws {
        let remote = StubMemberRemote(profileResult: .success(MemberProfileResponseDTO(
            name: "홍길동",
            email: "a@b.com",
            position: "WEB",
            careerLevel: "JUNIOR",
            thisWeekSolvedCount: 0,
            thisMonthSolvedCount: 0,
            streakDays: 0,
            weeklyChart: [],
        )))
        let adapter = MemberRepositoryAdapter(remote: remote)

        await #expect(throws: MemberError.temporarilyUnavailable) {
            try await adapter.fetchProfile()
        }
    }

    @Test(arguments: [
        DataMemberError.transport,
        DataMemberError.temporarilyUnavailable,
        DataMemberError.decoding,
    ])
    func `transport·5xx·decoding 오류를 재시도 가능한 Domain 오류로 변환한다`(dataError: DataMemberError) async throws {
        let remote = StubMemberRemote(profileResult: .failure(dataError))
        let adapter = MemberRepositoryAdapter(remote: remote)

        await #expect(throws: MemberError.temporarilyUnavailable) {
            try await adapter.fetchProfile()
        }
    }

}

// MARK: - StubMemberRemote

private actor StubMemberRemote: MemberRemote {

    // MARK: Lifecycle

    init(profileResult: Result<MemberProfileResponseDTO, DataMemberError> = .failure(.unexpectedStatus)) {
        self.profileResult = profileResult
    }

    // MARK: Internal

    private(set) var recordedPositionRequest: PositionRequestDTO?

    func fetchProfile() async throws -> MemberProfileResponseDTO {
        try profileResult.get()
    }

    func registerDeviceInfo(_: DeviceInfoRequestDTO) async throws { }

    func curateMember(_: CurationRequestDTO) async throws { }

    func updatePosition(_ request: PositionRequestDTO) async throws {
        recordedPositionRequest = request
    }

    func updateCareerLevel(_: CareerLevelRequestDTO) async throws { }

    func withdrawMember() async throws { }

    // MARK: Private

    private let profileResult: Result<MemberProfileResponseDTO, DataMemberError>

}
