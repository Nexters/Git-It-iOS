import Testing

@testable import DomainMember

// MARK: - UpdateMemberCareerLevelTests

@Suite("UpdateMemberCareerLevel")
struct UpdateMemberCareerLevelTests {
    @Test
    func `career만 요청하고 position은 건드리지 않는다`() async throws {
        let repository = UpdateMemberCareerLevelRepository()
        let updateMemberCareerLevel = UpdateMemberCareerLevel(repository: repository)

        try await updateMemberCareerLevel(.senior)

        #expect(await repository.requestedCareerLevel == .senior)
        #expect(await repository.positionUpdateCallCount == 0)
    }
}

// MARK: - UpdateMemberCareerLevelRepository

private actor UpdateMemberCareerLevelRepository: MemberRepository {
    private(set) var requestedCareerLevel: CareerLevel?
    private(set) var positionUpdateCallCount = 0

    func completeCuration(
        position _: MemberPosition,
        careerLevel _: CareerLevel,
    ) async throws { }
    func fetchProfile() async throws -> MemberProfile {
        throw MemberError.memberUnavailable
    }

    func updatePosition(_: MemberPosition) async throws {
        positionUpdateCallCount += 1
    }

    func updateCareerLevel(_ careerLevel: CareerLevel) async throws {
        requestedCareerLevel = careerLevel
    }

    func registerDevice(_: MemberDeviceInfo) async throws { }
    func deleteAccount() async throws { }
}
