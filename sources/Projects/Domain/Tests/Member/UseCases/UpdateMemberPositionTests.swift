import Testing

@testable import DomainMember

// MARK: - UpdateMemberPositionTests

@Suite("UpdateMemberPosition")
struct UpdateMemberPositionTests {
    @Test
    func `position만 요청하고 career는 건드리지 않는다`() async throws {
        let repository = UpdateMemberPositionRepository()
        let updateMemberPosition = UpdateMemberPosition(repository: repository)

        try await updateMemberPosition(.backend)

        #expect(await repository.requestedPosition == .backend)
        #expect(await repository.careerUpdateCallCount == 0)
    }

    @Test
    func `실패하면 이전 상태에 영향을 주지 않는다`() async throws {
        let repository = UpdateMemberPositionRepository(behavior: .fail)
        let updateMemberPosition = UpdateMemberPosition(repository: repository)

        await #expect(throws: MemberError.temporarilyUnavailable) {
            try await updateMemberPosition(.backend)
        }
    }
}

// MARK: - UpdateMemberPositionRepository

private actor UpdateMemberPositionRepository: MemberRepository {

    // MARK: Lifecycle

    init(behavior: Behavior = .succeed) {
        self.behavior = behavior
    }

    // MARK: Internal

    enum Behavior: Sendable {
        case succeed
        case fail
    }

    private(set) var requestedPosition: MemberPosition?
    private(set) var careerUpdateCallCount = 0

    func completeCuration(
        position _: MemberPosition,
        careerLevel _: CareerLevel,
    ) async throws { }
    func fetchProfile() async throws -> MemberProfile {
        throw MemberError.memberUnavailable
    }

    func updatePosition(_ position: MemberPosition) async throws {
        requestedPosition = position
        if case .fail = behavior {
            throw MemberError.temporarilyUnavailable
        }
    }

    func updateCareerLevel(_: CareerLevel) async throws {
        careerUpdateCallCount += 1
    }

    func registerDevice(_: MemberDeviceInfo) async throws { }
    func deleteAccount() async throws { }

    // MARK: Private

    private let behavior: Behavior

}
